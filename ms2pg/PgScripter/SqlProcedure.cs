using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ms2pg.PgScripter
{
    internal class SqlProcedure
    {
        public string Name { get; }
        public List<SqlProcedureParameter> Parameters { get; }

        public SqlProcedure (string name)
        {
            Name = name;
            Parameters = new List<SqlProcedureParameter> ();
        }
    }
}
