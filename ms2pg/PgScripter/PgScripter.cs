

namespace ms2pg.PgScripter
{
    internal class PgScripter
    {
        /// <summary>
        /// Script all files 
        /// </summary>
        /// <param name="config"></param>
        public static void pgScript(Config.Config config)
        {
            var baseDirectory = config["ms-parsed-dir"];
            var convertToDirectory = config["pg-script-dir"];
            var xsltFileName = config["xslt-file-name"];
            var files = Directory.GetFiles(baseDirectory, "*.xml", SearchOption.AllDirectories)
                .Select(x =>
                new
                {
                    XmlFileName = x,
                    OutputFileName = Path.Combine(convertToDirectory, Path.GetRelativePath(baseDirectory, Path.ChangeExtension(x, "sql")))                    
                }).ToList();

            files.Sort((x, y) => x.OutputFileName.CompareTo(y.OutputFileName));

            var filesFilters = new List<String>();
            if (config.ContainsKey("file-name-contains-filters"))
            {
                filesFilters.AddRange(
                    config["file-name-contains-filters"]
                    .Split(',')
                    .Where(x => !String.IsNullOrEmpty(x)));
            }

            foreach (var file in files)
            {
                if (filesFilters.Count == 0 || filesFilters.Where(x => file.OutputFileName.Contains(x)).Count() > 0)
                {
                    Console.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}\tgenerating sql\t{file.XmlFileName} => {file.OutputFileName}");
                    var OutputDirectoryName = Path.GetDirectoryName(file.OutputFileName);
                    if (!Directory.Exists(OutputDirectoryName)) { Directory.CreateDirectory(OutputDirectoryName!); }
                    MsParsedToPgXsltTransform.GenerateScript(file.XmlFileName, xsltFileName, file.OutputFileName, config);
                }
            }

        }
    }
}
