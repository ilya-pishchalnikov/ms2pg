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
        public HashSet<object> ObjectsStack = new HashSet<object>();

        public HashSet<string> ExcludedProperties = new HashSet<string>();

        public bool IsEnumerableItemNameAsParentWithoutS = true;
        public bool IsDebugMessages = false;
        public bool IsIgnoreSerializationErrors = true;
        public bool IsAddType = false;
        public bool IsTypeAsElementName = true;
        public bool IsIgnoreUntypedProperties = false;

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
                rootXmlElement = xmlResult.CreateElement(obj.GetType().Name);
            }
            else
            {
                rootXmlElement = xmlResult.CreateElement("xml");
            }
            
            xmlResult.AppendChild(rootXmlElement);
            Serialize(obj, rootXmlElement);

            return xmlResult;
        }
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

                        if (IsIgnoreUntypedProperties && property.GetType().Name == "RuntimePropertyInfo") 
                        {
                            Serialize(property.GetValue(obj)!, currentElement);
                            continue;
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