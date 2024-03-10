using Npgsql;

namespace ms2pg.PgDeploy
{
    internal class PgDeploy
    {
        public static void Deploy(Config.Config config)
        {
            var baseDirectory = config["pg-script-dir"];
            var files = new List<string>();
            var directoryStack = new Stack<string>();
            var directoryMatching = new Dictionary<string, string>();

            directoryStack.Push(baseDirectory);

            while (directoryStack.Count > 0)
            {
                var currentDirectory = directoryStack.Pop();
                files.AddRange(Directory.GetFiles(currentDirectory));
                Directory.GetDirectories(currentDirectory).ToList().ForEach(directory => { directoryStack.Push(directory); });
            }

            var connectionString = config["pg-connection-string"];
            using (var connection = new Npgsql.NpgsqlConnection(connectionString))
            {
                connection.Open();
                foreach (var file in files)
                    using (var command = connection.CreateCommand())
                    {
                        try
                        {
                            command.CommandText = File.ReadAllText(file);
                            command.ExecuteNonQuery();
                        }
                        catch (Exception ex)
                        {
                            throw new Exception($"Error while deploy file '{file}' with message: '{ex.Message}'", ex);
                        }
                        Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\texecuting sql\t{file} => PostgreSQL");
                    }
            }
        }
    }
}
