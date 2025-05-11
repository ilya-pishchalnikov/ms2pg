using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ms2pg.Config
{
    internal class ConfigActions : List<ConfigAction>
    {
        public bool IsWriteOutput = true;
        public void Do()
        {
            foreach (var action in this)
            {
                if (IsWriteOutput)
                {
                    Console.WriteLine(action.Name + " executing...");
                }
                action.Do();
                if (IsWriteOutput)
                {
                    Console.WriteLine($"{action.Name} executed in {action.Duration} ms");
                }
            }

            if (IsWriteOutput)
            {
                Console.WriteLine("Timings: ");
                foreach (var action in this)
                {
                    Console.WriteLine($"{action.Name} executed in {action.Duration} ms");
                }
            }
        }
    }
}
