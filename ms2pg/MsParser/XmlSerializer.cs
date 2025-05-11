using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml;
using System.Collections;

namespace ms2pg.MsParser
{
    public class XmlSerializer
    {

        /// <summary>
        /// Used objects stack to avoid an endless loop
        /// </summary>
        private HashSet<object> ObjectsStack = new HashSet<object>();

        /// <summary>
        /// Objects that should not be included in the parsing result
        /// </summary>
        public HashSet<string> ExcludedProperties = new HashSet<string>();

        /// <summary>
        /// The elements of the IEnumerable list in xml are named the same as the parent element without ending with -s or -es
        /// </summary>
        public bool IsEnumerableItemNameAsParentWithoutS = true;
        /// <summary>
        /// Show debug messages if true
        /// </summary>
        public bool IsDebugMessages = false;
        /// <summary>
        /// Ignore serialization errors if true
        /// </summary>
        public bool IsIgnoreSerializationErrors = true;
        /// <summary>
        /// Add attribute with type name to each element if true
        /// </summary>
        public bool IsAddType = false;
        /// <summary>
        /// Use type name as element name if true
        /// </summary>
        public bool IsTypeAsElementName = true;
        /// <summary>
        /// Untyped properties (RuntimePropertyType) ignored if true
        /// </summary>
        public bool IsIgnoreUntypedProperties = false;
        /// <summary>
        /// Serialize object to XmlDocument
        /// </summary>
        /// <param name="obj">Object to serialize</param>
        /// <returns>XML document parse result</returns>
        public XmlDocument Serialize(object obj)
        {
            if (IsDebugMessages)
            {
                Console.WriteLine($"Start serialization of object {obj.GetType().FullName}");
            }
            var xmlResult = new XmlDocument();
            XmlDeclaration xmlDeclaration = xmlResult.CreateXmlDeclaration("1.0", "UTF-8", null);
            XmlElement rootXmlElement = null!; 
            if (IsTypeAsElementName)
            {
                rootXmlElement = xmlResult.CreateElement(obj.GetType().Name.Replace("`", "_"));
            }
            else
            {
                rootXmlElement = xmlResult.CreateElement("xml");
            }
            
            xmlResult.AppendChild(rootXmlElement);
            Serialize(obj, rootXmlElement);

            return xmlResult;
        }

        /// <summary>
        /// Recursively serialize object to xml element
        /// </summary>
        /// <param name="obj">Object to serialize</param>
        /// <param name="currentElement">start element to serialize object</param>
        /// <returns>XML element parse resule</returns>
        /// <exception cref="Exception"></exception>
        private XmlElement Serialize(object obj, XmlElement currentElement)
        {
            if (IsDebugMessages)
            {
                Console.WriteLine($"Serializing {obj.GetType().FullName}");
            }

            if (obj == null) return currentElement;
            if (ObjectsStack.Contains(obj)) return null!;
            ObjectsStack.Add(obj);

            if (IsAddType)
            {
                currentElement.SetAttribute("type", obj.GetType().Name);
            }

            if (obj is IEnumerable)
            {
                var itemName = "item";

                if (IsEnumerableItemNameAsParentWithoutS)
                {
                    if (currentElement.Name.Length > 2 && currentElement.Name.EndsWith("es"))
                    {
                        itemName = currentElement.Name.Substring(0, currentElement.Name.Length - 2);
                    }
                    else if (currentElement.Name.Length > 1 && currentElement.Name.EndsWith("s"))
                    {
                        itemName = currentElement.Name.Substring(0, currentElement.Name.Length - 1);
                    }
                }
                foreach (var item in (obj as IEnumerable)!)
                {
                    if (IsTypeAsElementName) 
                    {
                        itemName = item.GetType().Name;
                    }
                    var childElement = currentElement.OwnerDocument.CreateElement(itemName);
                    currentElement.AppendChild(childElement);
                    Serialize(item, childElement);
                }
                return currentElement;
            }

            var childElement1 = currentElement.OwnerDocument.CreateElement(obj.GetType().Name);
            if (currentElement.Name != childElement1.Name)
            {
                currentElement.AppendChild(childElement1);
                currentElement = childElement1;
            }
            foreach (var property in obj.GetType().GetProperties().Where(p => p.CanRead && p.GetIndexParameters().Length == 0))
            {
                try
                {
                    if (IsDebugMessages)
                    {
                        Console.WriteLine($"Serializing property {property.Name}");
                    }

                    if (ExcludedProperties.Contains(property.Name))
                    {
                        continue;
                    }

                    var propertyValue = property.GetValue(obj);
                    if (property.GetValue(obj) == null)
                    {
                        currentElement.SetAttribute(property.Name, null);
                        continue;
                    }
                    if (IsSimpleType(property.GetValue(obj)!.GetType()))
                    {
                        currentElement.SetAttribute(property.Name, property.GetValue(obj)!.ToString());
                        continue;
                    }
                    else
                    {
                        String elementName = property.Name;
                        if (IsTypeAsElementName && property.GetType().Name != "RuntimePropertyInfo") 
                        {
                            elementName = property.GetType().Name;
                        }

                        var childElement = currentElement.OwnerDocument.CreateElement(elementName);
                        currentElement.AppendChild(childElement);
                        Serialize(property.GetValue(obj)!, childElement);
                    }
                }
                catch (Exception ex)
                {
                    if (!IsIgnoreSerializationErrors)
                    {
                        throw new Exception($"Exception while processing property {property.Name}", ex);
                    }
                    else
                    {
                        Console.WriteLine($"Exception while processing property {property.Name}: {ex.Message}\n{ex.StackTrace}");
                    }
                }
            }
            ObjectsStack.Remove(obj);
            return currentElement;
        }

        /// <summary>
        /// Check if type is simple scalar
        /// </summary>
        /// <param name="type">Type to check</param>
        /// <returns>True if type is simple</returns>
        private bool IsSimpleType(Type type)
        {
            if (type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Nullable<>))
            {
                // nullable type, check if the nested type is simple.
                return IsSimpleType(type.GetGenericArguments()[0]);
            }
            return type.IsPrimitive
              || type.IsEnum
              || type.Equals(typeof(string))
              || type.Equals(typeof(decimal));
        }
    }
}