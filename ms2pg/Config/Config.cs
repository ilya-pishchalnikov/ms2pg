using Microsoft.SqlServer.TransactSql.ScriptDom;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace ms2pg.Config
{
    internal enum OnErrorAction { Raise, Suppress }
    internal class Config
    {
        public ConfigProperties CommonProperties;
        public ConfigActions Actions = new ConfigActions();

        public string ConfigFileName { get; }
        public Config(string configFileName = "config.xml")
        {
            ConfigFileName = configFileName;
            var xmlDocument = new XmlDocument();
            xmlDocument.Load(ConfigFileName);

            CommonProperties = GetProperties(xmlDocument, "/ms2pg-config/common/property");

            var xmlNodesActions = xmlDocument.SelectNodes("/ms2pg-config/actions/action");

            if (xmlNodesActions != null)
            {
                foreach (XmlNode xmlAction in xmlNodesActions!)
                {
                    var actionConfigProperties = new ConfigProperties();
                    actionConfigProperties =  new ConfigProperties (CommonProperties);
                    actionConfigProperties.Add(GetProperties(xmlAction.SelectNodes("property")!));
                    var configActionType = new ConfigActionType();
                    switch (xmlAction.Attributes!["type"]!.Value.ToString())
                    {
                        case "clear-folder":
                            configActionType = ConfigActionType.ClearFolder;
                            break;
                        case "script-ms-sql":
                            configActionType = ConfigActionType.ScriptMsSql;
                            break;
                        case "parse-ms-sql":
                            configActionType = ConfigActionType.ParseMsSql;
                            break;
                        case "script-pg-sql":
                            configActionType = ConfigActionType.ScriptPgSql;
                            break;
                        case "deploy-pg-sql":
                            configActionType = ConfigActionType.DeployPgSql;
                            break;
                        case "format-ms-sql":
                            configActionType = ConfigActionType.FormatMsSql;
                            break;
                        default:
                            throw new ArgumentException($"Unknown type {xmlAction.Attributes!["type"]!.Value.ToString()}");
                    }
                    var enabled = xmlAction.Attributes["enabled"]?.Value.ToString() == "true";
                    var onErrorAction = xmlAction.Attributes["on-error"]?.Value.ToString() == "suppress" ? OnErrorAction.Suppress : OnErrorAction.Raise;

                    Actions.Add(new ConfigAction(xmlAction.Attributes!["name"]!.Value.ToString(), actionConfigProperties, configActionType, enabled, onErrorAction));
                }
            }
        }


        private ConfigProperties GetProperties(XmlDocument xmlDocument, string xPath)
        {
            var nodes = xmlDocument.SelectNodes(xPath);
            
            return GetProperties(nodes);
        }

        private ConfigProperties GetProperties(XmlNodeList nodes)
        {
            var result = new ConfigProperties();
            if (nodes is not null)
            {
                foreach (XmlElement node in nodes)
                {
                    var property = GetProperty(node);
                    result.Add(property.Key, property.Value);
                }
            }
            return result;
        }

        private KeyValuePair<string, string> GetProperty (XmlElement node)
        {
            var name = node.Attributes["name"]?.InnerText;
            var value = node.Attributes["value"]?.InnerText;
            var variable = node.Attributes["variable"]?.InnerText;
            var propertyValue = node.Attributes["property-value"]?.InnerText;
            if (name == null || (value == null && variable == null && propertyValue == null))
            {
                throw new ApplicationException($"Свойства (property) в файле должны содержать атрибуты name и value либо variable, либо property-value");
            }
            if (value == null && variable != null)
            {
                value = System.Environment.GetEnvironmentVariable(variable!);
            }
            if (value == null && propertyValue != null)
            {
                value = CommonProperties[propertyValue];
            }
            if (value == null)
            {
                throw new ApplicationException($"Environvent variable '{variable}' not found");
            }
            return new KeyValuePair<string, string>(name, value);
        }
    }
}
