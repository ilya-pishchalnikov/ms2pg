using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Sdk.Sfc;
using Microsoft.SqlServer.Management.Smo;
using System.Net;
using System.Reflection;
using System.Runtime.CompilerServices;

namespace ms2pg.MsScripter
{
    /// <summary>
    /// Script MSSQL database into files
    /// </summary>
    internal static class ObjectsScripter
    {
        /// <summary>
        /// Scripts all objects of database. 
        /// </summary>
        /// <param name="config">Application configuration</param>
        public static void ScriptAllObjects (Config.Config config)
        {
            using var connection = new SqlConnection(config["ms-connection-string"].Replace("ms2pg", "lv"));
            var server = new Server(new ServerConnection(connection));
            var database = server.Databases[connection.Database];
            var t = (
                from property in database.GetType().GetProperties()
                where property.GetType() == typeof(TableCollection)
                select property
                ).ToList();



            var scriptableObjects = database.GetType()
                .GetProperties(BindingFlags.Public | BindingFlags.Instance)
                .Where(x => x.PropertyType.BaseType == typeof(SchemaCollectionBase))
                .ToList()
                .Select(x => x.GetValue(database) as SchemaCollectionBase);



            foreach (SchemaCollectionBase scriptableObject in scriptableObjects.Cast<SchemaCollectionBase>())
            {
                ObjectsCollectionScriptToFile.ScriptToFiles(scriptableObject, config["ms-script-dir"], true, config);
            }
        }
    }
}
