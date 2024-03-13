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
        /// <summary>
        /// Generates Postgre Sql script from xml file with parsed MS SQL script
        /// </summary>
        /// <param name="xmlFileName"></param>
        /// <param name="xsltFileName"></param>
        /// <param name="outputFileName"></param>
        /// <param name="config"></param>
        /// <returns></returns>
        public static void GenerateScript(string xmlFileName, string xsltFileName, string outputFileName, Config.Config config)
        {
            try 
            {
                var xslt = new XslCompiledTransform();
                var xsltSettings = new XsltSettings(true, true);

                var xsltArguments = new XsltArgumentList();
                xsltArguments.AddExtensionObject("urn:custom", new XsltExtensionFunctions());

                xslt.Load(xsltFileName, xsltSettings, new XmlUrlResolver());
                //Execute the XSLT transform.
                using (var outputStream = new FileStream(outputFileName, FileMode.Create))
                {

                    xslt.Transform(xmlFileName, xsltArguments, outputStream);

                }

                var rawScriptText = File.ReadAllText(outputFileName);

                var IndentedText = PostProcessIndents(rawScriptText);
                
                var statementsToAfterScript = config["statements-to-after-script"].Split(",").ToList();
                var postProcessedScript = new StringBuilder();
                var postProcessedAfterScript = new StringBuilder();
                PostProcessStatements(IndentedText, statementsToAfterScript, out postProcessedScript, out postProcessedAfterScript);
                File.WriteAllText(outputFileName, postProcessedScript.ToString());
                var afterScriptFilePath = Path.Combine(config["pg-after-script-dir"], Path.GetFileName(outputFileName));
                if (postProcessedAfterScript.Length > 0) 
                {
                    File.WriteAllText(afterScriptFilePath, postProcessedAfterScript.ToString());
                }
            }
            catch (Exception ex)
            {
                throw new ApplicationException($"Error while translating file {xmlFileName} into Postgre SQL.", ex);
            }
            
        }

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
        /// <summary>
        /// Не поддерживает вложенность выносимых в пособработку стейтментов
        /// </summary>
        /// <param name="rawScriptText"></param>
        /// <param name="statementsToAfterScript"></param>
        /// <param name="script"></param>
        /// <param name="afterScript"></param>
        private static void PostProcessStatements (string rawScriptText, List<string> statementsToAfterScript, out StringBuilder script, out StringBuilder afterScript)
        {         
            var tokensStatements = StatementBeginEndRegEx().Split(rawScriptText.ToString());
            var isAfterScript = false;
            script = new StringBuilder();
            afterScript = new StringBuilder();

            foreach (var token in tokensStatements)
            {
                string statementName = string.Empty;
                if (token.StartsWith("{{StatementBegin:"))
                {
                    statementName = token.Split(":")[1];
                    statementName = statementName.Substring(0,statementName.Length - 2);
                    isAfterScript = statementsToAfterScript.Contains(statementName);
                }
                else if (token.StartsWith("{{StatementEnd:"))
                {                    
                    statementName = token.Split(":")[1];
                    statementName = statementName.Substring(0,statementName.Length - 2);
                    if (statementsToAfterScript.Contains(statementName)) {
                        isAfterScript = false;
                    }
                }
                else
                {
                    if (isAfterScript) {                        
                        afterScript.Append(token);
                    }
                    else {
                        script.Append(token);
                    }
                }
            }
        }

        [GeneratedRegex("({{Indent\\+\\+}}|{{Indent--}}|\\r\\n|\\n\\r|\\r|\\n)")]
        private static partial Regex IndentsRegex();
        

        [GeneratedRegex("({{StatementBegin:[^}]+}}|{{StatementEnd:[^}]+}})")]
        private static partial Regex StatementBeginEndRegEx ();
        

        [GeneratedRegex("{{StatementBegin:[^}]+}}")]
        private static partial Regex StatementBeginRegEx ();


        [GeneratedRegex("{{StatementEnd:[^}]+}}")]
        private static partial Regex StatementEndRegEx ();
    }
}
