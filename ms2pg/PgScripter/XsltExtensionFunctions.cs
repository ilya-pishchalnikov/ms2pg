using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.XPath;
using System.Xml.Xsl;

namespace ms2pg.PgScripter
{
    /// <summary>
    /// Класс, реализующий функции расширения для xslt
    /// </summary>
    public class XsltExtensionFunctions
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="expression"></param>
        /// <param name="pattern"></param>
        /// <param name="replacement"></param>
        /// <returns></returns>
        public string RegexReplace(string expression, string pattern, string replacement) => Regex.Replace(expression, pattern, replacement);
    }
}
