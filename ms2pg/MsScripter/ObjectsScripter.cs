using Microsoft.Data.SqlClient;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Sdk.Sfc;
using Microsoft.SqlServer.Management.Smo;
using Microsoft.SqlServer.TransactSql.ScriptDom;
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
        public static void ScriptAllObjects (Config.ConfigProperties config)
        {
            using var connection = new SqlConnection(config["ms-connection-string"]);
            {
                var server = new Server(new ServerConnection(connection));
                var database = server.Databases[connection.Database];

                var scriptableObjects = database.GetType()
                    .GetProperties(BindingFlags.Public | BindingFlags.Instance)
                    .Where(x => GetBaseTypes(x.PropertyType).Contains(typeof (SchemaCollectionBase)))
                    .Select(x => x.GetValue(database) as SchemaCollectionBase);

                foreach (SchemaCollectionBase scriptableObject in scriptableObjects.Cast<SchemaCollectionBase>())
                {
                    ObjectsCollectionScriptToFile.ScriptToFiles(scriptableObject, config["ms-script-dir"], true, config);
                }

                var simpleScriptableObjects = database.GetType()
                    .GetProperties(BindingFlags.Public | BindingFlags.Instance)
                    .Where(x => GetBaseTypes(x.PropertyType).Contains(typeof (SimpleObjectCollectionBase)))
                    .Where(x => !"WorkloadManagementWorkloadClassifierCollection,ExternalStreamCollection,ExternalStreamingJobCollection,WorkloadManagementWorkloadGroupCollection".Split(",").Contains(x.PropertyType.Name))
                    .Select(x => x.GetValue(database) as SimpleObjectCollectionBase);

                foreach (SimpleObjectCollectionBase scriptableObject in simpleScriptableObjects.Cast<SimpleObjectCollectionBase>())
                {
                    ObjectsCollectionScriptToFile.ScriptToFiles(scriptableObject, config["ms-script-dir"], true, config);
                }

                File.WriteAllText(config["ms-script-dir"] + "\\Schema\\dbo.sql" , "CREATE SCHEMA dbo;\n");
            } 
           
        }

        private static IEnumerable<Type> GetBaseTypes(this Type? type)
        {
            if (type == null) return new List<Type>();
            if(type.BaseType == null) return type.GetInterfaces();

                return Enumerable.Repeat(type.BaseType, 1)
                                .Concat(type.GetInterfaces())
                                .Concat(type.GetInterfaces().SelectMany<Type, Type>(GetBaseTypes))
                                .Concat(type.BaseType.GetBaseTypes());
            }
    }
}
