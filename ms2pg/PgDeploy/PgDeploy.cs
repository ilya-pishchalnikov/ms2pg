using System.Text.RegularExpressions;
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
        private static List<String> getFileNamesRecursively (string baseDirectory, string excludeDirectory = null!) 
        {
            var files = new List<string>();
            
            if (baseDirectory == null) return files;

            var directoryStack = new Stack<string>();

            directoryStack.Push(baseDirectory);

            while (directoryStack.Count > 0)
            {
                var currentDirectory = directoryStack.Pop();
                if (excludeDirectory!= null && Path.GetFullPath(currentDirectory) == Path.GetFullPath(excludeDirectory))
                {
                    continue;
                }
                files.AddRange(Directory.GetFiles(currentDirectory));
                Directory.GetDirectories(currentDirectory).ToList().ForEach(directory => { directoryStack.Push(directory); });
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
            var afterScriptDirectory = config["pg-after-script-dir"];
            var scriptDirSequence = config["pg-deploy-dir-sequence"].Split(",");
            var files = new List<string>();
            foreach (var scriptDir in scriptDirSequence)
            {
                var dirFilesList = getFileNamesRecursively(Path.Combine(baseDirectory, scriptDir));
                dirFilesList.Sort();
                files.AddRange(dirFilesList);
            }
            // Add postprocessing files to the end of list
            files.AddRange(getFileNamesRecursively(afterScriptDirectory));

            var connectionString = config["pg-connection-string"];
            using (var connection = new Npgsql.NpgsqlConnection(connectionString))
            {
                connection.Open();
                foreach (var file in files)
                {
                    using (var command = connection.CreateCommand())
                    {
                        try
                        {
                            command.CommandText = File.ReadAllText(file);
                            command.ExecuteNonQuery();
                        }
                        catch (Exception ex)
                        {
                            if (Regex.IsMatch (ex.Message, "42P01: relation \".+\" does not exist" ))
                            {
                                files.Append(file);
                                continue;
                            }
                            throw new ApplicationException($"Error while deploying file '{file}'", ex);
                            
                        }
                        Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\texecuting sql\t{file} => PostgreSQL");
                    }
                }
            }
        }
    }
}
