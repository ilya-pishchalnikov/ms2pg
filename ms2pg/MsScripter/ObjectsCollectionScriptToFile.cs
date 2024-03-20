using Microsoft.SqlServer.Management.Smo;

namespace ms2pg.MsScripter
{
    /// <summary>
    /// 
    /// </summary>
    internal static class ObjectsCollectionScriptToFile
    {
        public static void ScriptToFiles(this SchemaCollectionBase objectsCollection, string folderName, bool isOwerwrite, Config.Config config)
        {
            var objectTypeName =
                (from method in objectsCollection.GetType().GetMethods()
                 where method.Name == "get_Item"
                 select method.ReturnType
                ).First().Name;


            if (!Directory.Exists(Path.Combine(folderName, objectTypeName)))
            {
                Directory.CreateDirectory(Path.Combine(folderName, objectTypeName));
            }

            var filesFilters = new List<String>();
            if (config.ContainsKey("file-name-contains-filters"))
            {
                filesFilters.AddRange(
                    config["file-name-contains-filters"]
                    .Split(',')
                    .Where(x => !String.IsNullOrEmpty(x)));
            }
            
            foreach (ScriptSchemaObjectBase smoObject in objectsCollection)
            {
                var filename = Path.Combine(folderName, objectTypeName, smoObject.Schema + "." + smoObject.Name + ".sql");
                
                if (filesFilters.Count == 0 || filesFilters.Where(x => filename.Contains(x)).Count() > 0)
                {
                    if (smoObject.Schema == "sys")
                    {
                        continue;
                    }
                    bool? isSystemObject = (bool?)(smoObject.Properties["IsSystemObject"]?.Value);
                    if (isSystemObject is not null && isSystemObject == true)
                    {
                        continue;
                    }
                    
                    Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\tscripting\t{smoObject.Schema}.{smoObject.Name} => {filename}");
                    (smoObject as IScriptable)!.ScriptToFile(filename, isOwerwrite);
                }
            }
        }
    }
}
