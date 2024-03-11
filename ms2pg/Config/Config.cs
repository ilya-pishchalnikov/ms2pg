using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Xml;

namespace ms2pg.Config
{
    internal class Config : Dictionary<string, string>
    {
        public string ConfigFileName { get; }
        public Config(string configFileName = "config.xml")
        {
            ConfigFileName = configFileName;
            var xmlDocument = new XmlDocument();
            xmlDocument.Load(ConfigFileName);

            var nodes = xmlDocument.SelectNodes("/ms2pg-config/property");

            if (nodes is not null)
            {
                foreach (XmlElement node in nodes)
                {
                    var name = node.Attributes["name"]?.InnerText;
                    var value = node.Attributes["value"]?.InnerText;
                    var variable = node.Attributes["variable"]?.InnerText;
                    if (name == null || (value == null && variable == null))
                    {
                        throw new ApplicationException($"Свойства (property) в файле '{configFileName}' должны содержать атрибуты name и value либо variable (Чувствительно к регистру)");
                    }
                    if (value == null) {
                        value = System.Environment.GetEnvironmentVariable(variable!);
                        if (value == null) {
                            throw new ApplicationException($"Environvent variable '{variable}' not found");
                        }
                    }

                    Add(name, value);
                }
            }
        }
    }
}
