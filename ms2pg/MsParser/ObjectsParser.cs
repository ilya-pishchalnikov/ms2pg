//using Microsoft.SqlServer.Management.SqlParser.Parser;
using System.Text;
//using Microsoft.SqlServer.Management.SqlParser.Common;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using System.Xml;
//using Microsoft.SqlServer.Management.SqlParser.SqlCodeDom;
using System.Text.RegularExpressions;
using System.CodeDom;
using ms2pg.Config;

namespace ms2pg.MsParser
{
    /// <summary>
    /// MS SQL file parser to xml
    /// </summary>
    internal static class ObjectsParser
    {
        /// <summary>
        /// Парсинг файлов .sql формата MS SQL и запись в файлы .xml
        /// </summary>
        /// <param name="baseDirectory">Путь по которому находятся файлы</param>
        public static void ParseFiles(Config.Config config)
        {
            var baseDirectory = config["ms-parsed-dir"];

            string[] files = Directory.GetFiles(baseDirectory, "*.sql", SearchOption.AllDirectories);

            foreach (var file in files)
            {
                ParseFile(file, config);
            }

        }

        /// <summary>
        /// Парсинг sql файла 
        /// </summary>
        /// <param name="fileName"></param>
        public static void ParseFile(string fileName, Config.Config config)
        {
            Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\tparsing\t{fileName} => {Path.ChangeExtension(fileName, ".xml")}");

            var sqlParser = new Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser(true);

            var textReaderSql = new StringReader(File.ReadAllText(fileName, Encoding.UTF8));
            IList<ParseError> parseErrors = null!;

            var parseResult = sqlParser.Parse(textReaderSql,out parseErrors);

            if (parseErrors != null && parseErrors.Count > 0) {
                var parseErrorsString = parseErrors
                    .Select(err => $"[file: {fileName} line:{err.Line}, col:{err.Column}] {err.Message}")
                    .Aggregate((msg1, msg2) => msg1 + "\n" + msg2);
                throw new ApplicationException ($"Errors while file parsing: \n {parseErrorsString}");
            }
            
            var serializer = new ms2pg.MsParser.XmlSerializer ();
            serializer.IsDebugMessages = config["is-debug-messages"] == "true";
            serializer.IsEnumerableItemNameAsParentWithoutS = config["is-xml-enumerables-name-like-parent"] == "true";
            foreach (var excludedProperty in config["excluded-properties"].Split(","))
            {
                serializer.ExcludedProperties.Add(excludedProperty);
            }

            var parseResultXml = serializer.Serialize(parseResult);


            var parseResultXmlString = new StringBuilder();
            var settings = new XmlWriterSettings
            {
                Indent = true,
                IndentChars = "  ",
                NewLineChars = "\r\n",
                NewLineHandling = NewLineHandling.Replace,
                Encoding = Encoding.UTF8
            };
            using XmlWriter writer = XmlWriter.Create(parseResultXmlString, settings);
            parseResultXml.Save(Path.ChangeExtension(fileName, ".xml"));
        }
    }
}
