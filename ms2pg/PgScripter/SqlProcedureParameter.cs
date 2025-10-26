using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ms2pg.PgScripter
{
    internal class SqlProcedureParameter
    {
        public string Name { get; }
        public string Type { get; }
        public int Id { get; }
        public bool IsOutput { get; }
        public SqlProcedureParameter(string name, string type, int id, bool isOutput)
        {
            Name = name;
            Type = type;
            Id = id;
            IsOutput = isOutput;
        }
    }
}
