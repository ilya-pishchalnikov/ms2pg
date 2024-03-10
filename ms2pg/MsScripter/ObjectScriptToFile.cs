using Microsoft.SqlServer.Management.Smo;
using System.Text;

namespace ms2pg.MsScripter
{
    internal static class ObjectScriptToFile
    {
        public static void ScriptToFile(this IScriptable dbObject, string path, bool isOverwrite) 
        {
            if (isOverwrite || !File.Exists(path))
            {
                var scriptingOptions = new ScriptingOptions
                {
                    AllowSystemObjects = false,
                    ChangeTracking = true,
                    ClusteredIndexes = true,
                    ColumnStoreIndexes = true,
                    ConvertUserDefinedDataTypesToBaseType = true,
                    Encoding = Encoding.UTF8,
                    ExtendedProperties = true,
                    FileName = path,
                    FullTextCatalogs = true,
                    FullTextIndexes = true,
                    FullTextStopLists = true,
                    IncludeDatabaseContext = true,
                    IncludeDatabaseRoleMemberships = true,
                    IncludeFullTextCatalogRootPath = true,
                    Indexes = true,
                    NoAssemblies = false,
                    NoCollation = true,
                    NoViewColumns = false,
                    NoFileGroup = true,
                    NoIndexPartitioningSchemes = true,
                    OptimizerData = true,
                    Permissions = true,
                    PrimaryObject = true,
                    ScriptBatchTerminator = true,
                    ScriptDataCompression = true,
                    ScriptForCreateOrAlter = true,
                    ScriptOwner = false,
                    ScriptSchema = true,
                    ScriptXmlCompression = true,
                    SpatialIndexes = true,
                    Statistics = true,
                    TimestampToBinary = false,
                    WithDependencies = false,
                    XmlIndexes = true,
                    Default = true,
                    Triggers = true,
                    DriAll = false,
                    DriAllConstraints = false,
                    DriChecks = true,
                    DriAllKeys = true,
                    DriDefaults = true
                };

               dbObject.Script(scriptingOptions);
            }
        }
    }
}
