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
            int position = 1;
            var beforeErrorBatchPart = string.Empty;
            switch(exception.Data["SqlState"])
            {
                case "42883": // Operator does not exist
                    if ((exception.Data["MessageText"] as string)!.Contains("character varying + character varying"))
                    {
                        position = (int) exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position);
                        var plusSignIndex = Regex.Match(new string(beforeErrorBatchPart.Reverse().ToArray()), "/+").Index;
                        fixedBatch = beforeErrorBatchPart.Substring(0, position - plusSignIndex - 1) + "|| "
                                + batch.Substring(position - plusSignIndex + 1);
                    }
                    break;
                case "22P02": // 
                    if ((exception.Data["MessageText"] as string)!.Contains("integer: \"\""))
                    {
                        position = (int) exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position - 1);
                        fixedBatch = beforeErrorBatchPart.Substring(0, position - 1) + "0"
                                + batch.Substring(position + 1);
                    }
                    break;
            }

            if (fixedBatch != null)
            {    
                batches[batchIndex] = fixedBatch;
                File.WriteAllText(fileName, batches.Aggregate((x,y) => x + "\n{{GO}}\n" + y));
                return true;
            }
            else
            {                    
                if (exception.Data.Contains("Position"))
                {
                    position = (int) exception.Data["Position"]!;
                }
                beforeErrorBatchPart = batch.Substring(0, position > 0 ? position-1 : 0);
                fixedBatch = beforeErrorBatchPart 
                        + $"/*!ERROR HERE!: '{exception.Data["SqlState"] as string}:{exception.Data["MessageText"] as string}'*/"
                        + batch.Substring(position-1);
                batches[batchIndex] = fixedBatch;
                File.WriteAllText(fileName, batches.Aggregate((x,y) => x + "\n{{GO}}\n" + y));
                return false;
            }
        }
    }
}