using ms2pg.MsParser;
using ms2pg.MsScripter;

namespace ms2pg
{
    class Program
    {

        static void Main()
        {
            var config = new Config.Config();
            ObjectsScripter.ScriptAllObjects(config);
            ObjectsParser.ParseFiles(config);
            PgScripter.PgScripter.pgScript(config);
            PgDeploy.PgDeploy.Deploy(config);
        }
    }
}
