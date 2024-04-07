using System.Collections;
using System.Runtime.CompilerServices;
using System.Security.Cryptography.X509Certificates;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using Microsoft.VisualBasic;
using Npgsql;

namespace ms2pg.PgDeploy
{
    /// <summary>
    /// Deploy PostgreSQL scripts from files
    /// </summary>
    internal class PgDeploy
    {
        /// <summary>
        /// Recursively get files (list of paths) from directory except excludeDirectory
        /// </summary>
        /// <param name="baseDirectory">Directory from which files will get</param>
        /// <param name="excludeDirectory">Except directory. Default null</param>
        /// <returns>List of files paths</returns>
        private static List<String> getFileNamesRecursively(string baseDirectory, string excludeDirectory = null!)
        {
            var files = new List<string>();

            if (baseDirectory == null) return files;

            var directoryStack = new Stack<string>();

            directoryStack.Push(baseDirectory);

            while (directoryStack.Count > 0)
            {
                var currentDirectory = directoryStack.Pop();
                if (excludeDirectory != null && Path.GetFullPath(currentDirectory) == Path.GetFullPath(excludeDirectory))
                {
                    continue;
                }
                if (Directory.Exists(currentDirectory))
                {
                    files.AddRange(Directory.GetFiles(currentDirectory));
                    Directory.GetDirectories(currentDirectory).ToList().ForEach(directory => { directoryStack.Push(directory); });
                }
            }
            return files;
        }

        /// <summary>
        /// Deploy PostgreSQL scripts from files
        /// </summary>
        /// <param name="config">Application configuration dictionary</param>
        /// <exception cref="Exception"></exception>
        public static void Deploy(Config.Config config)
        {
            var baseDirectory = config["pg-script-dir"];
            var scriptDirSequence = config["pg-deploy-dir-sequence"].Split(",");
            var files = new List<string>();
            foreach (var scriptDir in scriptDirSequence)
            {
                var dirFilesList = getFileNamesRecursively(Path.Combine(baseDirectory, scriptDir));
                dirFilesList.Sort();
                files.AddRange(dirFilesList);
            }

            var filesFilters = new List<String>();
            if (config.ContainsKey("file-name-contains-filters"))
            {
                filesFilters.AddRange(
                    config["file-name-contains-filters"]
                    .Split(',')
                    .Where(x => !String.IsNullOrEmpty(x)));
            }
            
            var ErrorCount = 1000;

            if (config.ContainsKey("deploy-retry-count"))
            {
                ErrorCount = Int32.Parse(config["deploy-retry-count"]);
            }

            var connectionString = config["pg-connection-string"];
            using (var connection = new Npgsql.NpgsqlConnection(connectionString))
            {
                connection.Open();

                var batches = new Queue<String>();
                var errors = new List<string>();
                var unsolvableCount = 0;

                foreach (var file in files)
                {
                    if (filesFilters.Count == 0 || filesFilters.Where(x => file.Contains(x)).Count() > 0)
                    {
                        Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\texecuting sql\t{file} => PostgreSQL");
                        var script = File.ReadAllText(file);
                        string[] fileBatches = script.Split("{{GO}}");
                        for(int i = 0; i < fileBatches.Length; i++)
                        {
                            try
                            {
                                DeployBatch(connection, fileBatches[i]);
                            }
                            catch (PostgresException ex)
                            {
                                var solveResult = ErrorsSolver.Solve(ex, fileBatches, i, file, config);
                                switch (solveResult)
                                {
                                    case ErrorsSolver.SolveResult.Solved:
                                        Console.WriteLine ("Error fixed");
                                        i--;
                                        batches.Enqueue(fileBatches[i]);
                                        break;
                                    case ErrorsSolver.SolveResult.Unsolved:
                                        ErrorCount--;
                                        batches.Enqueue(fileBatches[i]);
                                        break;
                                    case ErrorsSolver.SolveResult.Unsolvable:
                                        errors.Add(fileBatches[i]);
                                        ErrorCount--;
                                        unsolvableCount++;
                                        break;
                                }
                                
                                Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\terror while deploying file \t{file}: {ex.Message}");
                                if (ErrorCount <= 0)
                                {
                                    File.WriteAllText("errors.sql", errors.Aggregate( (x, y) => x + "\n\n/*GO*/\n\n" + y) + "\n\n/*GO*/\n\n" + batches.Where(x => x.Contains("!ERROR IN BATCH!")).Aggregate( (x, y) => x + "\n\n/*GO*/\n\n" + y));
                                    throw new ApplicationException($"Error count exceeds limit. Undeployed batches ({batches.Count + unsolvableCount}) saved to errors.sql");
                                }
                            }
                        }
                    }
                }

                var listOfErrorsHash = 0;
                var hashSameCount = 0;

                while (batches.Count > 0)
                {
                    var batch = batches.Dequeue();
                    Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\texecuting sql batch => PostgreSQL");
                    try
                    {
                        DeployBatch(connection, batch);
                    }
                    catch (Exception ex)
                    {
                        ErrorCount--;
                        batches.Enqueue(batch);
                        var currentHash = GetOrderIndependentHashCode(batches);

                        if (currentHash == listOfErrorsHash)
                        {
                            hashSameCount++;
                            if (hashSameCount > batches.Count())
                            {
                                ErrorCount = 0;
                            }
                        }
                        else{
                            listOfErrorsHash = currentHash;
                            hashSameCount = 0;
                        }

                        Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\terror while deploying batch\nERROR: {ex.Message}");
                        if (ErrorCount <= 0)
                        {
                            var errorsString = string.Empty;
                            if (errors.Count > 0) 
                            {
                                errorsString = errors.Aggregate( (x, y) => x + "\n\n/*GO*/\n\n" + y) + "\n\n/*GO*/\n\n";
                            }
                            File.WriteAllText("errors.sql",errorsString + batches.Aggregate( (x, y) => x + "\n\n/*GO*/\n\n" + y));
                             throw new ApplicationException($"Error count exceeds limit. Undeployed batches ({batches.Count}) saved to errors.sql");
                        }
                    }
                }

                if (errors.Count > 0)
                {                            
                    File.WriteAllText("errors.sql", errors.Aggregate( (x, y) => x + "\n\n/*GO*/\n\n" + y) + "\n\n/*GO*/\n\n" );
                    throw new ApplicationException($"Error count exceeds limit. Undeployed batches ({unsolvableCount}) saved to errors.sql");
                }
            }
        }


        private static void DeployBatch(Npgsql.NpgsqlConnection connection, string batch)
        {
            if (String.IsNullOrEmpty(batch))
            {
                return;                                 
            }
            using (var command = connection.CreateCommand())
            {
                command.CommandText = batch;
                command.ExecuteNonQuery();
            }
        }

        private static int GetOrderIndependentHashCode<T>(IEnumerable<T> source)
        {
            int hash = 0;
            foreach (T element in source)
            {
                hash = hash ^ EqualityComparer<T>.Default.GetHashCode(element);
            }
            return hash;
        }
    }
}
