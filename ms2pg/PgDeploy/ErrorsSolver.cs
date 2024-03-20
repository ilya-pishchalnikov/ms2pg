using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace ms2pg.PgDeploy
{
    public static class ErrorsSolver
    {
        public static bool Solve (Npgsql.PostgresException exception, string[] batches, int batchIndex, string fileName)
        {
            var batch = batches[batchIndex];
            string fixedBatch = null;
            switch(exception.Data["SqlState"])
            {
                case "42883": // Operator does not exist
                    if ((exception.Data["MessageText"] as string)!.Contains("character varying + character varying"))
                    {
                        var position = (int) exception.Data["Position"]!;
                        string beforeErrorBatchPart = batch.Substring(0, position);
                        var plusSignIndex = Regex.Match(new string(beforeErrorBatchPart.Reverse().ToArray()), "/+").Index;
                        fixedBatch = beforeErrorBatchPart.Substring(0, position - plusSignIndex - 1) + "|| "
                                + batch.Substring(position - plusSignIndex + 1);
                    }
                    break;
            }
            if (fixedBatch != null )
            {
                batches[batchIndex] = fixedBatch;
                File.WriteAllText(fileName, batches.Aggregate((x,y) => x + "\n{{GO}}\n" + y));
                return true;
            }
            return false;
        }
    }
}