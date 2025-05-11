using System.Diagnostics;
using Microsoft.SqlServer.Management.HadrModel;
using ms2pg.MsParser;
using ms2pg.MsScripter;

namespace ms2pg
{
    class Program
    {

        static void Main(string[] args)
        {
            if (args.Length > 1)
            {
                throw new ArgumentException("None or one parameter expected");
            }

            string fileName = string.Empty;
            if (args.Length == 1)
            {
                fileName = args[0];
            }
            else {
                fileName = "config.xml";
            }

            var config = new Config.Config();   
            config.Actions.Do();
            
        }
    }
}
