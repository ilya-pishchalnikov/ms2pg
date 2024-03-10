using Microsoft.SqlServer.Management.Smo;

namespace ms2pg.MsScripter
{
    internal static class ObjectsCollectionScriptToFile
    {
        public static void ScriptToFiles(this SchemaCollectionBase objectsCollection, string folderName, bool isOwerwrite)
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

            foreach (ScriptSchemaObjectBase smoObject in objectsCollection)
            {
                if (smoObject.Schema == "sys") { continue; }
                bool? isSystemObject = (bool?)(smoObject.Properties["IsSystemObject"]?.Value);
                if (isSystemObject is not null && isSystemObject == true) { continue; }
                var filename = Path.Combine(folderName, objectTypeName, smoObject.Schema + "." + smoObject.Name + ".sql");
                Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\tscripting\t{smoObject.Schema}.{smoObject.Name} => {filename}");
                (smoObject as IScriptable)!.ScriptToFile(filename, isOwerwrite);
            }
        }

    }
}
