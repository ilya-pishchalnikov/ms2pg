using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace ms2pg.PgDeploy
{
    public static class ErrorsSolver
    {
        public enum SolveResult {Solved, Unsolved, Unsolvable};
        public static SolveResult Solve(Npgsql.PostgresException exception, string[] batches, int batchIndex, string fileName)
        {
            var batch = batches[batchIndex];
            string fixedBatch = null;
            int position = 1;
            var beforeErrorBatchPart = string.Empty;
            var afterErrorBatchPart = string.Empty;
            var solveResult = SolveResult.Unsolved;
            switch (exception.Data["SqlState"])
            {
                case "42883": // Operator does not exist
                    var messageText = exception.Data["MessageText"] as string;

                    if (Regex.IsMatch(messageText!, @"(character varying|text|unknown|name) \+ (character varying|text|unknown|name)"))
                    {

                        position = (int)exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position - 1);
                        afterErrorBatchPart = batch.Substring(position);
                        fixedBatch = beforeErrorBatchPart + " || " + afterErrorBatchPart;
                    }
                    else if (Regex.IsMatch(messageText!, "integer [+-=><] (character varying|character|text)"))
                    {

                        position = (int)exception.Data["Position"]!;
                        beforeErrorBatchPart = new string(batch.Substring(0, position - 1).Reverse().ToArray());
                        afterErrorBatchPart = batch.Substring(position - 1);

                        var match = Regex.Match(beforeErrorBatchPart, @"^[ \t\r\n]*(\d+|[0-9a-zA-Z_#]+([ \t\r\n]*\.+[ \t\r\n]*[0-9a-zA-Z_#]+)*)");

                        if (match.Success)
                        {
                            beforeErrorBatchPart = new string(beforeErrorBatchPart.Reverse().ToArray());
                            fixedBatch = beforeErrorBatchPart.Substring(0, beforeErrorBatchPart.Length - match.Length)
                                                 + " CAST("
                                                 + beforeErrorBatchPart.Substring(beforeErrorBatchPart.Length - match.Length, match.Length)
                                                 + " AS VARCHAR) "
                                                 + afterErrorBatchPart;
                        }
                    }
                    else if (Regex.IsMatch(messageText!, @"timestamp with time zone [+\-] integer"))
                    {

                        position = (int)exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position);
                        afterErrorBatchPart = batch.Substring(position);

                        var match = Regex.Match(afterErrorBatchPart, @"^[ \t\r\n]*\d+");

                        if (match.Success)
                        {
                            fixedBatch = beforeErrorBatchPart
                                                 + "  INTERVAL '"
                                                 + match.Value
                                                 + " day'"
                                                 + afterErrorBatchPart.Substring(match.Length);
                        }
                    }
                    else if (Regex.IsMatch(messageText!, "(character varying|character|text) [+-=><] integer"))
                    {

                        position = (int)exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position);
                        afterErrorBatchPart = batch.Substring(position);

                        var match = Regex.Match(afterErrorBatchPart, @"^[ \t\r\n]*(\d+|[0-9a-zA-Z_#]+([ \t\r\n]*\.+[ \t\r\n]*[0-9a-zA-Z_#]+)*)");

                        if (match.Success)
                        {

                            fixedBatch = beforeErrorBatchPart
                                        + " CAST("
                                        + afterErrorBatchPart.Substring(0, match.Length)
                                        + " AS VARCHAR) "
                                        + afterErrorBatchPart.Substring(match.Length);
                        }
                    }
                    break;
                case "22007": // 
                    position = (int)exception.Data["Position"]!;
                    beforeErrorBatchPart = batch.Substring(0, position - 1);
                    afterErrorBatchPart = batch.Substring(position - 1);
                    if (afterErrorBatchPart.StartsWith("''"))
                    {
                        fixedBatch = beforeErrorBatchPart + "null"
                                + batch.Substring(position + 1);
                    }
                    break;
                case "42804":
                    messageText = exception.Data["MessageText"] as string;
                    if (Regex.IsMatch(messageText!, "(character varying|character|text) .+ integer"))
                    {
                        position = (int)exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position - 1);
                        afterErrorBatchPart = batch.Substring(position - 1);
                        var match = Regex.Match(afterErrorBatchPart, @"^[ \t\r\n]*(\d+|[0-9a-zA-Z_#]+([ \t\r\n]*\.+[ \t\r\n]*[0-9a-zA-Z_#]+)*)");
                        if (match.Success)
                        {
                            fixedBatch = beforeErrorBatchPart + "CAST (" + match.Value + " AS VARCHAR) "
                                        + afterErrorBatchPart.Substring(match.Length);
                        }
                    }
                    break;
                case "22P02": // 
                    if ((exception.Data["MessageText"] as string)!.Contains("integer: \"\""))
                    {
                        position = (int)exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position - 1);
                        fixedBatch = beforeErrorBatchPart.Substring(0, position - 1) + "0"
                                + batch.Substring(position + 1);
                    }
                    break;
                case "42P16": // 
                    if (Regex.IsMatch(batch, "CREATE OR REPLACE VIEW"))
                    {
                        var viewName = Regex.Match(batch, @"(?<=CREATE OR REPLACE VIEW[\t\r\n ]+)([a-zA-Z0-9_]+([\t\r\n ]*\.[a-zA-Z0-9_]+)*)").Value;
                        fixedBatch = $"DROP VIEW {viewName};\n" + batch;
                    }
                    break;
                case "42725": // Operator does not exist
                    messageText = exception.Data["MessageText"] as string;

                    if (Regex.IsMatch(messageText!, @"(character varying|text|unknown|name) \+ (character varying|text|unknown|name)"))
                    {

                        position = (int)exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position - 1);
                        afterErrorBatchPart = batch.Substring(position);
                        fixedBatch = beforeErrorBatchPart + " || " + afterErrorBatchPart;
                    }
                    break;
                case "42601" :
                    solveResult = SolveResult.Unsolvable;
                    break;
                case "42704" :
                    messageText = exception.Data["MessageText"] as string;
                    if (messageText.Contains("serial_in_function_return"))
                    {
                        var splitted = batch.Split("SERIAL_IN_FUNCTION_RETURN");
                        if (splitted.Count() == 3) {
                            fixedBatch = splitted[0] + "INT" + splitted[1] + "SERIAL" + splitted[2];
                        }
                    }
                    break;
            }

            if (fixedBatch != null)
            {
                batches[batchIndex] = fixedBatch;
                File.WriteAllText(fileName, batches.Aggregate((x, y) => x + "\n{{GO}}\n" + y));
                return SolveResult.Solved;
            }
            else
            {
                if (exception.Data.Contains("Position"))
                {
                    position = (int)exception.Data["Position"]!;
                }
                beforeErrorBatchPart = batch.Substring(0, position > 0 ? position - 1 : 0);
                fixedBatch = $"/*!ERROR IN BATCH!: file: '({fileName})' Message:'{exception.Data["SqlState"] as string}:{exception.Data["MessageText"] as string}'*/\n"
                        + beforeErrorBatchPart
                        + $"/*!ERROR HERE!: file: '({fileName})' Message:'{exception.Data["SqlState"] as string}:{exception.Data["MessageText"] as string}'*/"
                        + batch.Substring(position - 1);
                batches[batchIndex] = fixedBatch;
                File.WriteAllText(fileName, batches.Aggregate((x, y) => x + "\n{{GO}}\n" + y));
                return solveResult;
            }
        }
    }
}