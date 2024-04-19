using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ms2pg
{
    public class FileExtensions
    {
        public static void EmptyFolder (string folderPath, List<string> foldersToExclude)
        {
            if (Path.Exists(folderPath)) 
            {
                Directory.GetFiles(folderPath, "*.*", SearchOption.AllDirectories)
                    .Select(x => x.Replace("/", "\\"))
                    .Where (x => foldersToExclude.Where(y => y.Contains(x)).Count() == 0)
                    .ToList().ForEach(x => File.Delete(x));
            }
        }
    }
}