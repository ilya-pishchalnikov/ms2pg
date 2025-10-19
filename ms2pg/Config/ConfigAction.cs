using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ms2pg.MsScripter;
using ms2pg.MsParser;

namespace ms2pg.Config
{

    internal enum ConfigActionType { ClearFolder, ScriptMsSql, ParseMsSql, ScriptPgSql, DeployPgSql, FormatMsSql };

    internal class ConfigAction
    {
        public string Name { get; }
        public ConfigProperties Properties { get; }
        public ConfigActionType Type { get; }
        public long Duration { get => _Duration; }
        private long _Duration;
        public OnErrorAction OnErrorAction { get;}
        public bool Enabled = false;
        public ConfigAction (string name, ConfigProperties properties, ConfigActionType type, bool enabled = false, OnErrorAction onErrorAction = OnErrorAction.Raise)
        {
            Name = name;
            Properties = properties;
            Type = type;
            Enabled = enabled;
            OnErrorAction = onErrorAction;
        }

        public void Do()
        {
            if (!Enabled) return;

            var stopWatch = new Stopwatch();

            stopWatch.Start();
            try
            {
                switch (Type)
                {
                    case ConfigActionType.ClearFolder:
                        FileExtensions.EmptyFolder(Properties["dir"], Properties.ContainsKey("exclude") ? Properties["exclude"].Split(",").ToList() : null);
                        break;
                    case ConfigActionType.ScriptMsSql:
                        ObjectsScripter.ScriptAllObjects(Properties);
                        break;
                    case ConfigActionType.ParseMsSql:
                        ObjectsParser.ParseFiles(Properties);
                        break;
                    case ConfigActionType.ScriptPgSql:
                        PgScripter.PgScripter.pgScript(Properties);
                        break;
                    case ConfigActionType.DeployPgSql:
                        PgDeploy.PgDeploy.Deploy(Properties);
                        break;
                    case ConfigActionType.FormatMsSql:
                        MsFormatter.MsFormatter.msFormat(Properties);
                        break;
                    default:
                        throw new InvalidOperationException($"Unknown action {Type}");
                }
            }
            catch (Exception ex)
            {
                if (OnErrorAction == ms2pg.Config.OnErrorAction.Suppress)
                {
                    Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\tError in action\t{ex.Message}");
                }
                else
                {
                    throw;
                }
            }
            stopWatch.Stop();
            _Duration = stopWatch.ElapsedMilliseconds;
        }
        
    }
}
