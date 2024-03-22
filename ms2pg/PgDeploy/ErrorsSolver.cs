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
            var afterErrorBatchPart = string.Empty;
            switch(exception.Data["SqlState"])
            {
                case "42883": // Operator does not exist
                    var messageText = exception.Data["MessageText"] as string;
                    
                    if (Regex.IsMatch(messageText!, @"(character varying|text) \+ (character varying|text)"))
                    {

                        position = (int) exception.Data["Position"]!;
                        beforeErrorBatchPart = batch.Substring(0, position - 1);
                        afterErrorBatchPart = batch.Substring(position);
                        fixedBatch = beforeErrorBatchPart + " || " + afterErrorBatchPart;
                    }
                    else if (Regex.IsMatch(messageText!, "integer [+-=><] (character varying|character|text)"))
                    {
                        
                        position = (int) exception.Data["Position"]!;                        
                        beforeErrorBatchPart = new string (batch.Substring(0, position - 1).Reverse().ToArray());
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
                        
                        position = (int) exception.Data["Position"]!;
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
                        
                        position = (int) exception.Data["Position"]!;                        
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
                    position = (int) exception.Data["Position"]!;
                    beforeErrorBatchPart = batch.Substring(0, position - 1);
                    afterErrorBatchPart = batch.Substring(position - 1);
                    if (afterErrorBatchPart.StartsWith("''"))
                    {
                        fixedBatch = beforeErrorBatchPart + "null"
                                + batch.Substring(position + 1);
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
                fixedBatch = $"/*!ERROR IN BATCH!: '{exception.Data["SqlState"] as string}:{exception.Data["MessageText"] as string}'*/\n"
                        + beforeErrorBatchPart 
                        + $"/*!ERROR HERE!: '{exception.Data["SqlState"] as string}:{exception.Data["MessageText"] as string}'*/"
                        + batch.Substring(position-1);
                batches[batchIndex] = fixedBatch;
                File.WriteAllText(fileName, batches.Aggregate((x,y) => x + "\n{{GO}}\n" + y));
                return false;
            }
        }
    }
}