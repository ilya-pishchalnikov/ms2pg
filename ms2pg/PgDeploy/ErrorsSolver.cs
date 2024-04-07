using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using Npgsql;

namespace ms2pg.PgDeploy
{
    public static class ErrorsSolver
    {
        public enum SolveResult {Solved, Unsolved, Unsolvable};
        public static SolveResult Solve(Npgsql.PostgresException exception, string[] batches, int batchIndex, string fileName, Config.Config config)
        {
            var batch = batches[batchIndex];
            string fixedBatch = null;
            var beforeErrorBatchPart = string.Empty;
            var afterErrorBatchPart = string.Empty;
            var solveResult = SolveResult.Unsolved;
            var errorCode = exception.Data["SqlState"] as string;
            var errorMessage = exception.Data["MessageText"] as string;
            var errorPosition = 1;
            if (exception.Data.Contains("Position"))
            {
                errorPosition =(int)exception.Data["Position"]!;
            }

            if (errorMessage.StartsWith("{{CHECK ERROR}}"))
            {
                var connectionString = config["pg-connection-string"];
                var functionName = Regex.Match(errorMessage, @"\[\[.+\]\]").Value.Replace("[", "").Replace("]", "");
                using (var connection = new NpgsqlConnection(connectionString))
                {
                    connection.Open();
                    var sql = $"select sqlstate, position, query, message from public.plpgsql_check_function_tb('{functionName}') t where level = 'error'";
                    using(var command = new NpgsqlCommand(sql, connection))
                    using(var reader = command.ExecuteReader())
                    {
                        if (reader.HasRows)
                        {
                            reader.Read();
                            errorMessage = reader[3] as string;
                            errorCode = reader[0] as string;                            
                            var query = reader[2] as string;
                            
                            int queryPosition = 0;
                            if (query != null )
                            {
                                queryPosition = batch.IndexOf(query);
                            }
                            if (reader[1] != null && reader[1].GetType() != typeof (DBNull))
                            {
                                errorPosition = queryPosition + (int)reader[1];
                            }
                        }
                    }
                }
            }

            switch (errorCode)
            {
                case "42883": // Operator does not exist

                    if (Regex.IsMatch(errorMessage!, @"(character varying|text|unknown|name) \+ (character varying|text|unknown|name)"))
                    {

                        beforeErrorBatchPart = batch.Substring(0, errorPosition - 1);
                        afterErrorBatchPart = batch.Substring(errorPosition);
                        if (batch.Substring(errorPosition - 1, 1)=="+")
                        {
                            fixedBatch = beforeErrorBatchPart + " || " + afterErrorBatchPart;
                        }
                    }
                    else if (Regex.IsMatch(errorMessage!, "integer [+-=><] (character varying|character|text)"))
                    {

                        beforeErrorBatchPart = new string(batch.Substring(0, errorPosition - 1).Reverse().ToArray());
                        afterErrorBatchPart = batch.Substring(errorPosition - 1);

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
                    else if (Regex.IsMatch(errorMessage!, @"timestamp with time zone [+\-] integer"))
                    {
                        beforeErrorBatchPart = batch.Substring(0, errorPosition);
                        afterErrorBatchPart = batch.Substring(errorPosition);

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
                    else if (Regex.IsMatch(errorMessage!, "(character varying|character|text) [+-=><] integer"))
                    {
                        if (batch.Substring(errorPosition - 1).StartsWith("WHEN"))
                        {
                            errorPosition += 4;
                        }
                        beforeErrorBatchPart = batch.Substring(0, errorPosition);
                        afterErrorBatchPart = batch.Substring(errorPosition);

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
                    beforeErrorBatchPart = batch.Substring(0, errorPosition - 1);
                    afterErrorBatchPart = batch.Substring(errorPosition - 1);
                    if (afterErrorBatchPart.StartsWith("''"))
                    {
                        fixedBatch = beforeErrorBatchPart + "null"
                                + batch.Substring(errorPosition + 1);
                    }
                    break;
                case "42804":
                    if (Regex.IsMatch(errorMessage!, "(character varying|character|text) .+ integer"))
                    {
                        beforeErrorBatchPart = batch.Substring(0, errorPosition - 1);
                        afterErrorBatchPart = batch.Substring(errorPosition - 1);
                        var match = Regex.Match(afterErrorBatchPart, @"^[ \t\r\n]*(\d+|[0-9a-zA-Z_#]+([ \t\r\n]*\.+[ \t\r\n]*[0-9a-zA-Z_#]+)*)");
                        if (match.Success)
                        {
                            fixedBatch = beforeErrorBatchPart + "CAST (" + match.Value + " AS VARCHAR) "
                                        + afterErrorBatchPart.Substring(match.Length);
                        }
                    }
                    break;
                case "22P02": // 
                    if (errorMessage!.Contains("integer: \"\""))
                    {
                        beforeErrorBatchPart = batch.Substring(0, errorPosition - 1);
                        fixedBatch = beforeErrorBatchPart.Substring(0, errorPosition - 1) + "0"
                                + batch.Substring(errorPosition + 1);
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

                    if (Regex.IsMatch(errorMessage!, @"(character varying|text|unknown|name) \+ (character varying|text|unknown|name)"))
                    {

                        beforeErrorBatchPart = batch.Substring(0, errorPosition - 1);
                        afterErrorBatchPart = batch.Substring(errorPosition);
                        fixedBatch = beforeErrorBatchPart + " || " + afterErrorBatchPart;
                    }
                    break;
                case "42601" :
                    solveResult = SolveResult.Unsolvable;
                    break;
                case "42704" :
                    if (errorMessage!.Contains("serial_in_function_return"))
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
                beforeErrorBatchPart = batch.Substring(0, errorPosition > 0 ? errorPosition - 1 : 0);
                fixedBatch = $"/*!ERROR IN BATCH!: file: '({fileName})' Message:'{exception.Data["SqlState"] as string}:{exception.Data["MessageText"] as string}'*/\n"
                        + beforeErrorBatchPart
                        + $"/*!ERROR HERE!: file: '({fileName})' Message:'{exception.Data["SqlState"] as string}:{exception.Data["MessageText"] as string}'*/"
                        + batch.Substring(errorPosition - 1);
                batches[batchIndex] = fixedBatch;
                File.WriteAllText(fileName, batches.Aggregate((x, y) => x + "\n{{GO}}\n" + y));
                return solveResult;
            }
        }
    }
}