using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.Management.Smo;
using Npgsql;
using Npgsql.Internal.Postgres;

namespace ms2pg.DataMigration
{
    public class DataMigration
    {

        public static DataTable EnlistAllTables (Config.Config config)
        {
            var resultDataSet = new DataSet();
            var sql = File.ReadAllText("sqlscripts/TablesDependencies.sql");
            var connectionString = config["ms-connection-string"];
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();

                using (var adapter = new SqlDataAdapter (sql, connection))
                {
                    adapter.Fill(resultDataSet);
                }
            }

            return resultDataSet.Tables[0];
        }

        public static void MigrateTableData (string tableName, Config.Config config)
        {
            var connectionString = config["ms-connection-string"];
            using (var connection = new SqlConnection(connectionString))
            using (var pgconnection = new Npgsql.NpgsqlConnection(config["pg-connection-string"]))
            {
                connection.Open();
                pgconnection.Open();
                using (NpgsqlCommand command = new NpgsqlCommand($"DELETE FROM {tableName};", pgconnection))
                {
                    command.ExecuteNonQuery();
                }

                using (var command = new SqlCommand($"select * from {tableName};", connection))
                using (var reader = command.ExecuteReader())
                {
                    var batchTable = new DataTable(tableName);
                    for(int i=0; i<reader.FieldCount; i++)
                    {
                        batchTable.Columns.Add(reader.GetName(i), reader.GetFieldType(i));
                    }
                    while (reader.Read())
                    {
                        var row = batchTable.Rows.Add();
                        for (int i = 0; i<reader.FieldCount; i++)
                        {
                            row[i] = reader.GetValue(i);
                        }

                        if (batchTable.Rows.Count >= 100)
                        {
                            FlushDataTable (tableName, batchTable, pgconnection);
                        }

                    }
                    
                    FlushDataTable (tableName, batchTable, pgconnection);
                }

            }
        }

        private static void FlushDataTable (string tableName, DataTable table, NpgsqlConnection connection)
        {
            using (var writer = connection.BeginBinaryImport(
                $"copy {tableName} from STDIN (FORMAT BINARY)"))
            {
                foreach (DataRow row in table.Rows)
                {
                    writer.StartRow();
                    foreach (DataColumn column in table.Columns)
                    {
                        writer.Write(row[column]);
                    }
                }
                writer.Complete();
            }

            table.Clear();
        }
    }
}