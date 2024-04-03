using ms2pg.MsParser;
using ms2pg.MsScripter;

namespace ms2pg
{
    class Program
    {

        static void Main()
        {
            var config = new Config.Config();
            FileExtensions.EmptyFolder(config["ms-script-dir"], config["empty-ms-folder-exclude"].Split(",").ToList());
            FileExtensions.EmptyFolder(config["ms-parsed-dir"], config["empty-ms-folder-exclude"].Split(",").ToList());
            FileExtensions.EmptyFolder(config["pg-script-dir"], config["empty-pg-folder-exclude"].Split(",").ToList());
            ObjectsScripter.ScriptAllObjects(config);
            ObjectsParser.ParseFiles(config);
            PgScripter.PgScripter.pgScript(config);
            PgDeploy.PgDeploy.Deploy(config);
            //DataMigration.DataMigration.MigrateTableData("dbo.testTable", config);
        }
    }
}
