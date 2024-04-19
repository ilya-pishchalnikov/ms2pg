using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ms2pg.PgScripter
{
    public class ProcedureResultSetColumn
    {
        public readonly string ProcedureName;
        public readonly string ColumnName;
        public readonly string DataType;

        public ProcedureResultSetColumn (string procedureName, string columnName, string dataType)
        {
            ProcedureName = procedureName;
            ColumnName = columnName;
            DataType = dataType;
        }
    }
}