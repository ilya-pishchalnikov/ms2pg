using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Policy;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace ms2pg.PgScripter
{
    public class XsltExtensions
    {
        private Config.Config _Config;

        public XsltExtensions (Config.Config config)
        {
            _Config = config;
        }

        private string[] _Keywords = new string[] {
                "all",
                "analyse",
                "analyze",
                "and",
                "any",
                "array",
                "as",
                "asc",
                "asymmetric",
                "both",
                "case",
                "cast",
                "check",
                "collate",
                "column",
                "constraint",
                "create",
                "current_catalog",
                "current_date",
                "current_role",
                "current_time",
                "current_timestamp",
                "current_user",
                "default",
                "deferrable",
                "desc",
                "distinct",
                "do",
                "else",
                "end",
                "except",
                "false",
                "fetch",
                "for",
                "foreign",
                "from",
                "grant",
                "group",
                "having",
                "in",
                "initially",
                "intersect",
                "into",
                "lateral",
                "leading",
                "limit",
                "localtime",
                "localtimestamp",
                "not",
                "null",
                "offset",
                "on",
                "only",
                "or",
                "order",
                "placing",
                "primary",
                "references",
                "returning",
                "select",
                "session_user",
                "some",
                "symmetric",
                "system_user",
                "table",
                "then",
                "to",
                "trailing",
                "true",
                "union",
                "unique",
                "user",
                "using",
                "variadic",
                "when",
                "where",
                "window",
                "with"
            };
        public string QuoteName(string name)
        {            
            if (Regex.IsMatch(name, "^[^a-zA-Z_].+")
                || Regex.IsMatch(name, "[^a-zA-Z_0-9]")
                || _Keywords.Contains(name.ToLower()))
            {
                return $"\"{name}\"";
            }
            else 
            {
                return name;
            }
        }

        public string ToLower (string str)
        {
            return str.ToLower();
        }

        public string DoubleQuotes (string str)
        {
            return str.Replace("'", "''");
        }

        public string GetTableValuedFunctionTableDefinition (string functionName)
        {
            try
            {
                var functionFields = GetFunctionFields(functionName);
                return functionFields.Select(functionField => $"var_{functionField[0]} {functionField[1]}").Aggregate((x, y) => x + ",\n" + y);
            }
            catch (Exception ex)
            {
                return $"/*!ERROR HERE! {ex.Message}*/";
            }
        }

        public string GetTableValuedFunctionQueryFieldsDefinition (string functionName)
        {
            try
            {
                var functionFields = GetFunctionFields(functionName);
                return functionFields.Select(functionField => $"CAST ({functionField[0]} AS {functionField[1]})").Aggregate((x, y) => x + ",\n" + y);
            }
            catch (Exception ex)
            {
                return $"/*!ERROR HERE! {ex.Message}*/";
            }
        }       

        private List<List<string>> GetFunctionFields (string functionName)
        {
            var result = new List<List<string>>();
            var connectionString = _Config["ms-connection-string"];
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var sql = $"select count (*) from sys.parameters where object_id = object_id('{functionName}')";
                var parametersCount = 0;

                using (var command = new SqlCommand (sql, connection))
                {
                    parametersCount = (int)command.ExecuteScalar();
                }

                var parameters = string.Empty;
                for (int i = 0; i < parametersCount; i++)
                {
                    if (i > 0) parameters += ", ";
                    parameters += "default";
                }

                sql = "select top (0) *\n";
                sql += $"from {functionName}({parameters});\n";

                using (var command = new SqlCommand (sql, connection))
                using (var reader  = command.ExecuteReader())
                {
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        var fieldDefinition = new List<string>(2);
                        fieldDefinition.Add (QuoteName(reader.GetName(i)));
                        var fieldType = reader.GetFieldType(i);
                        switch (fieldType.Name)
                        {
                            case "Int32":
                                fieldDefinition.Add ("INT");
                                break;
                            case "Int64":
                                fieldDefinition.Add ("BIGINT");
                                break;
                            case "String":
                                fieldDefinition.Add ("TEXT");
                                break;
                            default:
                                fieldDefinition.Add (fieldType.Name);
                                break;
                        }
                        result.Add(fieldDefinition);
                    }
                }
            }
            return result;
        }
    }
}