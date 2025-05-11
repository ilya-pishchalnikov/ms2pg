using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Xsl;
using Microsoft.VisualBasic;

namespace ms2pg.PgScripter
{
    internal partial class MsParsedToPgXsltTransform
    {

        private static XslCompiledTransform xslt = null;
        private static XsltArgumentList xsltArguments = null;

        /// <summary>
        /// Generates Postgre Sql script from xml file with parsed MS SQL script
        /// </summary>
        /// <param name="xmlFileName"></param>
        /// <param name="xsltFileName"></param>
        /// <param name="outputFileName"></param>
        /// <param name="config"></param>
        /// <returns></returns>
        public static void GenerateScript(string xmlFileName, string xsltFileName, string outputFileName, Config.ConfigProperties config)
        {
            try 
            {

                if (xslt == null) 
                {
                    xslt = new XslCompiledTransform();
                    var xsltSettings = new XsltSettings(true, true);

                    xsltArguments = new XsltArgumentList();
                    
                    xslt.Load(xsltFileName, xsltSettings, new XmlUrlResolver());

                    var xsltExtensions = new XsltExtensions(config);
                    xsltArguments.AddExtensionObject("urn:ms2pg", xsltExtensions);
                }
                //Execute the XSLT transform.
                using (var outputStream = new FileStream(outputFileName, FileMode.Create))
                {

                    xslt.Transform(xmlFileName, xsltArguments, outputStream);

                }

                var rawScriptText = File.ReadAllText(outputFileName);

                var IndentedText = PostProcessIndents(rawScriptText);

                IndentedText = StatementBeginEndRegEx().Replace(IndentedText, "");

                File.WriteAllText(outputFileName, IndentedText);
            }
            catch (Exception ex)
            {
                throw new ApplicationException($"Error while translating file {xmlFileName} into Postgre SQL.", ex);
            }
            
        }
        /// <summary>
        /// Put indents into file
        /// </summary>
        /// <param name="rawScriptText">Script string</param>
        /// <returns>Script string with indents</returns>
        private static string PostProcessIndents (string rawScriptText)
        {
            // Increments processing
            var processedIndents = new StringBuilder();
            var indent = 0;
            //var tokensIndents = IndentsRegex().Matches(rawScriptText).Select(match =>match.Value).ToList();
            var tokens = IndentsRegex().Split(rawScriptText).ToList();
            foreach (var token in tokens) 
            {
                 switch(token)
                    {
                        case "{{Indent++}}":
                            indent += 4;
                            break;
                        case "{{Indent--}}":
                            indent -= 4;
                            if (indent < 0) { indent = 0; }
                            break;
                        case "\r\n":
                        case "\n\r":
                        case "\n":
                        case "\r":
                            processedIndents.Append(token);
                            processedIndents.Append(new string(' ', indent));
                            break;
                        default:
                            processedIndents.Append(token);
                            break;
                    }
            }

            return processedIndents.ToString();
        }


        [GeneratedRegex("({{Indent\\+\\+}}|{{Indent--}}|\\r\\n|\\n\\r|\\r|\\n)")]
        private static partial Regex IndentsRegex();
        

        [GeneratedRegex("({{StatementBegin:[^}]+}}|{{StatementEnd:[^}]+}})")]
        private static partial Regex StatementBeginEndRegEx ();

    }
}
