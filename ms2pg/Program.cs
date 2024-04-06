using System.Diagnostics;
using ms2pg.MsParser;
using ms2pg.MsScripter;

namespace ms2pg
{
    class Program
    {

        static void Main()
        {
            var config = new Config.Config();
            var stopWatch = new Stopwatch();

            stopWatch.Start();
            //var result = DataMigration.DataMigration.EnlistAllTables(config);
            // FileExtensions.EmptyFolder(config["ms-script-dir"], config["empty-ms-folder-exclude"].Split(",").ToList());
            // FileExtensions.EmptyFolder(config["ms-parsed-dir"], config["empty-ms-folder-exclude"].Split(",").ToList());
            // FileExtensions.EmptyFolder(config["pg-script-dir"], config["empty-pg-folder-exclude"].Split(",").ToList());
            stopWatch.Stop();
            var fileDeleteDuration = stopWatch.ElapsedMilliseconds;
            stopWatch.Reset();

            stopWatch.Start();
            // ObjectsScripter.ScriptAllObjects(config);
            stopWatch.Stop();
            var scriptAllObjectsDuration = stopWatch.ElapsedMilliseconds;
            stopWatch.Reset();

            stopWatch.Start();            
            // ObjectsParser.ParseFiles(config);
            stopWatch.Stop();
            var parseMsSqlDuration = stopWatch.ElapsedMilliseconds;
            stopWatch.Reset();

            stopWatch.Start();
            PgScripter.PgScripter.pgScript(config);
            stopWatch.Stop();
            var pgScriptDuration = stopWatch.ElapsedMilliseconds;
            stopWatch.Reset();

            stopWatch.Start();   
            try
            {
                PgDeploy.PgDeploy.Deploy(config);
            }
            catch (Exception ex)
            {
                Console.WriteLine ($"ERROR WHILE DEPLOY\nERROR:\n{ex.Message}\nSTACK:\n{ex.StackTrace}");
            }
            stopWatch.Stop();
            var pgDeployDuration = stopWatch.ElapsedMilliseconds;
            //DataMigration.DataMigration.MigrateTableData("dbo.testTable", config);

            Console.WriteLine($"Delete files duration {fileDeleteDuration} ms");
            Console.WriteLine($"Script MSSQL database duration {scriptAllObjectsDuration} ms");
            Console.WriteLine($"Parse MSSQL files duration  {parseMsSqlDuration} ms");
            Console.WriteLine($"Script PostgreSQL files duration  {pgScriptDuration} ms");
            Console.WriteLine($"Deploy PostgreSQL files duration  {pgDeployDuration} ms");
        }
    }
}
