using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Xml;

namespace ms2pg.Config
{
    public class ConfigProperties : Dictionary<string, string>
    {
        public ConfigProperties() { }
        public ConfigProperties(ConfigProperties configProperties)
        {
            this.Add(configProperties);
        }

        public void Add(ConfigProperties configProperties)
        {
            foreach (var item in configProperties)
            {
                if (this.ContainsKey(item.Key))
                {
                    this[item.Key] = item.Value;
                }
                else
                {
                    this.Add(item.Key, item.Value);
                }
            }
        }
    }
}
