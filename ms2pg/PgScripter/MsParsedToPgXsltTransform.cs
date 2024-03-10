using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Xsl;

namespace ms2pg.PgScripter
{
    internal partial class MsParsedToPgXsltTransform
    {
        public static string GenerateScript(string xmlFileName, string xsltFileName, string outputFileName)
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

            var postProcessedText = PostProcess(rawScriptText);
            File.WriteAllText(outputFileName, postProcessedText);
            return postProcessedText;
        }

        private static string PostProcess (string rawScriptText)
        {
            var output = new StringBuilder();
            var indent = 0;
            var tokens = TokensRegex().Matches(rawScriptText).Select(match => match.Value);
            foreach (var token in tokens)
            {
                var isFirstSymbolInLine = true;
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
                        output.Append(token);
                        isFirstSymbolInLine = true;
                        break;
                    default:
                        if (CustomIndentDeltaRegex().Match(token).Value.Length > 0)
                        {
                            var indentDeltaStr = CustomIndentDeltaParse().Replace(token, "$1$2");
                            indent += int.Parse(indentDeltaStr);
                            if (indent < 0) { indent = 0; }
                            break;
                        }
                        if (isFirstSymbolInLine) { output.Append(new string(' ', indent)); }
                        output.Append(token);
                        break;
                }
            }

            return output.ToString();
        }

        [GeneratedRegex("({{Indent\\+\\+}}|{{Indent--}}|{{Indent\\+=\\d+}}|{{Indent-=\\d+}}|\\r\\n|\\n\\r|\\r|\\n|[^\\r\\n{]+)")]
        private static partial Regex TokensRegex();


        [GeneratedRegex("{{Indent(-|/+)=(/d+)}}")]
        private static partial Regex CustomIndentDeltaRegex();


        [GeneratedRegex("{{Indent(-|/+)=(/d+)}}")]
        private static partial Regex CustomIndentDeltaParse();
    }
}
