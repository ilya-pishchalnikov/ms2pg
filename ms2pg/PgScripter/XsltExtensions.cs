using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ms2pg.PgScripter
{
    public class XsltExtensions
    {
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
                || Regex.IsMatch(name, "[^a-zA-Z_/d].+")
                || _Keywords.Contains(name.ToLower()))
            {
                return $"\"{name}\"";
            }
            else 
            {
                return name;
            }
        }
    }
}