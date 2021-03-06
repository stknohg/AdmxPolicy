using System;
using System.Collections.Generic;
namespace AdmxPolicy
{
    [Flags]
    public enum RegistryTypes
    {
        Unknown = 0,
        LocalMachine = 1,
        CurrentUser = 2,
        Both = LocalMachine + CurrentUser
    }

    public sealed class AdmlResource
    {
        private string _DisplayName;
        public string DisplayName { get { return _DisplayName; } }
        private string _Description;
        public string Description { get { return _Description; } }
        private Dictionary<string, string> _Strings = new Dictionary<string, string>();
        public Dictionary<string, string> Strings { get { return _Strings; } }
        private Dictionary<string, string> _Windows = new Dictionary<string, string>();
        public Dictionary<string, string> Windows { get { return _Windows; } }
        public AdmlResource()
        {
            _DisplayName = "";
            _Description = "";
        }
        public AdmlResource(string displayName, string description)
        {
            _DisplayName = displayName;
            _Description = description;
        }
    }

    public sealed class AdmxFileInfo
    {
        private string _Name;
        public string Name { get { return _Name; } }
        private string _DisplayName;
        public string DisplayName { get { return _DisplayName; } }
        private string _Description;
        public string Description { get { return _Description; } }
        private List<CategoryInfo> _Categories = new List<CategoryInfo>();
        public List<CategoryInfo> Categories { get { return _Categories; } }
        public AdmxFileInfo(string name, string displayName, string description)
        {
            _Name = name;
            _DisplayName = displayName;
            _Description = description;
        }
        public override string ToString()
        {
            return _Name;
        }
    }

    public sealed class CategoryInfo
    {
        private string _Name;
        public string Name { get { return _Name; } }
        private string _DisplayName;
        public string DisplayName { get { return _DisplayName; } }
        public CategoryInfo(string name, string displayName)
        {
            _Name = name;
            _DisplayName = displayName;
        }
    }

    public sealed class PolicyInfo
    {
        private AdmxFileInfo _FileInfo;
        public AdmxFileInfo FileInfo { get { return _FileInfo; } }
        public string FileName { get { return _FileInfo == null ? "" : _FileInfo.Name; } }
        private string _Name;
        public string Name { get { return _Name; } }
        private string _DisplayName;
        public string DisplayName { get { return _DisplayName; } }
        private string _ExplainText;
        public string ExplainText { get { return _ExplainText; } }
        private RegistryTypes _RegistryType;
        public RegistryTypes RegistryType { get { return _RegistryType; } }
        public string[] RegistryRootKeys
        {
            get
            {
                switch (_RegistryType)
                {
                    case RegistryTypes.LocalMachine: { return new string[] { "HKEY_LOCAL_MACHINE" }; }
                    case RegistryTypes.CurrentUser: { return new string[] { "HKEY_CURRENT_USER" }; }
                    case RegistryTypes.Both: { return new string[] { "HKEY_LOCAL_MACHINE", "HKEY_CURRENT_USER" }; }
                    default: { return new string[] { "" }; }
                }
            }
        }
        public string[] RegistryPSDrives
        {
            get
            {
                switch (_RegistryType)
                {
                    case RegistryTypes.LocalMachine: { return new string[] { "HKLM:" }; }
                    case RegistryTypes.CurrentUser: { return new string[] { "HKCU:" }; }
                    case RegistryTypes.Both: { return new string[] { "HKLM:", "HKCU:" }; }
                    default: { return new string[] { "" }; }
                }
            }
        }
        private string _RegistryPath;
        public string RegistryPath { get { return _RegistryPath; } }
        private PolicyValueInfo _ValueInfo;
        public PolicyValueInfo ValueInfo { get { return _ValueInfo; } }
        public PolicyInfo(AdmxFileInfo fileInfo, string name, string displayName, string explainText,
                          RegistryTypes registryType, string registryPath, PolicyValueInfo valueInfo)
        {
            _FileInfo = fileInfo;
            _Name = name;
            _DisplayName = displayName;
            _ExplainText = explainText;
            _RegistryType = registryType;
            _RegistryPath = registryPath;
            _ValueInfo = valueInfo;
        }
    }

    public enum ValueTypes
    {
        Unknown = 0,
        Delete,
        Decimal,
        LongDecimal,
        String
    }

    // same values as Microsoft.Win32.RegistryValueKind
    public enum RegistryValueKind
    {
        Unknown = 0,
        String = 1,
        DWord = 4,
        MultiString = 7,
        QWord = 11,
        None = -1
    }

    public sealed class ValueDefinition
    {
        private ValueTypes _Type;
        public ValueTypes Type { get { return _Type; } }
        public RegistryValueKind RegistryType
        {
            get 
            {
                switch (_Type)
                {
                    case ValueTypes.Delete: { return RegistryValueKind.None; }
                    case ValueTypes.Decimal: { return RegistryValueKind.DWord; }
                    case ValueTypes.LongDecimal: { return RegistryValueKind.QWord; }
                    case ValueTypes.String: { return RegistryValueKind.String; }
                    default: { return RegistryValueKind.Unknown; }
                }
            }
        }
        private object _Value;
        public object Value { get { return _Value; } }
        public ValueDefinition(ValueTypes type, object value)
        {
            _Type = type;
            _Value = value;
        }
        public override string ToString()
        {
            return String.Format("{0} : {1}", _Type, _Value);
        }
    }

    public static class DefaultValueDefinition
    {
        // maybe, maybe...
        public static readonly ValueDefinition Enabled = new ValueDefinition(ValueTypes.Decimal, (UInt32)1);
        public static readonly ValueDefinition Disabled = new ValueDefinition(ValueTypes.Delete, null);
    }

    public sealed class ValueDefinitionList
    {
        private List<ListItem> _Items = new List<ListItem>();
        public List<ListItem> Items { get { return _Items; } }
        private string _DefaultRegistryPath;
        public string DefaultRegistryPath { get { return _DefaultRegistryPath; } }
        public ValueDefinitionList()
        {
            _DefaultRegistryPath = "";
        }
        public ValueDefinitionList(string defaultRegistryPath)
        {
            _DefaultRegistryPath = defaultRegistryPath;
        }
    }

    public sealed class ListItem
    {
        private string _RegistryPath;
        public string RegistryPath { get { return _RegistryPath; } }
        private string _RegistryValueName;
        public string RegistryValueName { get { return _RegistryValueName; } }
        private ValueDefinition _Value;
        public ValueDefinition Value { get { return _Value; } }
        public ListItem(string registryPath, string registryValueName, ValueDefinition value)
        {
            _RegistryPath = registryPath;
            _RegistryValueName = registryValueName;
            _Value = value;
        }
    }

    public enum ElementTypes
    {
        Unknown = 0,
        Boolean,
        Decimal,
        LongDecimal,
        Text,
        MultiText,
        Enum,
        List
    }

    public interface IValueDefinitionElement
    {
        ElementTypes ElementType { get; }
        string Id { get; }
        string RegistryValueName { get; }
    }

    public abstract class ValueDefinitionElementBase : IValueDefinitionElement
    {
        public virtual ElementTypes ElementType { get { return ElementTypes.Unknown; } }
        private string _Id;
        public string Id { get { return _Id; } }
        private string _RegistryPath;
        public string RegistryPath { get { return _RegistryPath; } }
        private string _RegistryValueName;
        public string RegistryValueName { get { return _RegistryValueName; } }
        public ValueDefinitionElementBase(string id, string registryPath, string registryValueName)
        {
            _Id = id;
            _RegistryPath = registryPath;
            _RegistryValueName = registryValueName;
        }
    }

    public sealed class BooleanDefinitionElement : ValueDefinitionElementBase
    {
        public override ElementTypes ElementType { get { return ElementTypes.Boolean; } }
        private ValueDefinition _TrueValue;
        public ValueDefinition TrueValue { get { return _TrueValue; } }
        private ValueDefinition _FalseValue;
        public ValueDefinition FalseValue { get { return _FalseValue; } }
        private ValueDefinitionList _TrueList;
        public ValueDefinitionList TrueList { get { return _TrueList; } }
        public bool HasTrueList { get { return (_TrueList != null && _TrueList.Items.Count > 0); } }
        private ValueDefinitionList _FalseList;
        public ValueDefinitionList FalseList { get { return _FalseList; } }
        public bool HasFalseList { get { return (_FalseList != null && _FalseList.Items.Count > 0); } }
        [System.Management.Automation.HiddenAttribute]
        public void set_Properties(ValueDefinition trueValue, ValueDefinition falseValue, ValueDefinitionList trueList, ValueDefinitionList falseList)
        {
            _TrueValue = trueValue;
            _FalseValue = falseValue;
            _TrueList = trueList;
            _FalseList = falseList;
        }
        public BooleanDefinitionElement(string id, string registryPath, string registryValueName) : base(id, registryPath, registryValueName)
        {
        }
    }

    public sealed class DecimalDefinitionElement : ValueDefinitionElementBase
    {
        public override ElementTypes ElementType { get { return ElementTypes.Decimal; } }
        private bool _Required;
        public bool Required { get { return _Required; } }
        private Decimal _MinValue;
        public Decimal MinValue { get { return _MinValue; } }
        private Decimal _MaxValue = 9999;
        public Decimal MaxValue { get { return _MaxValue; } }
        private bool _StoreAsText;
        public bool StoreAsText { get { return _StoreAsText; } }
        private bool _Soft;
        public bool Soft { get { return _Soft; } }
        [System.Management.Automation.HiddenAttribute]
        public void set_Properties(bool required, Decimal minValue, Decimal maxValue, bool storeAsText, bool soft)
        {
            _Required = required;
            _MinValue = minValue;
            _MaxValue = maxValue;
            _StoreAsText = storeAsText;
            _Soft = soft;
        }
        public DecimalDefinitionElement(string id, string registryPath, string registryValueName) : base(id, registryPath, registryValueName)
        {
        }
    }

    public sealed class LongDecimalDefinitionElement : ValueDefinitionElementBase
    {
        public override ElementTypes ElementType { get { return ElementTypes.LongDecimal; } }
        private bool _Required;
        public bool Required { get { return _Required; } }
        private Decimal _MinValue;
        public Decimal MinValue { get { return _MinValue; } }
        private Decimal _MaxValue = 9999;
        public Decimal MaxValue { get { return _MaxValue; } }
        private bool _StoreAsText;
        public bool StoreAsText { get { return _StoreAsText; } }
        private bool _Soft;
        public bool Soft { get { return _Soft; } }
        [System.Management.Automation.HiddenAttribute]
        public void set_Properties(bool required, Decimal minValue, Decimal maxValue, bool storeAsText, bool soft)
        {
            _Required = required;
            _MinValue = minValue;
            _MaxValue = maxValue;
            _StoreAsText = storeAsText;
            _Soft = soft;
        }
        public LongDecimalDefinitionElement(string id, string registryPath, string registryValueName) : base(id, registryPath, registryValueName)
        {
        }
    }

    public sealed class TextDefinitionElement : ValueDefinitionElementBase
    {
        public override ElementTypes ElementType { get { return ElementTypes.Text; } }
        private bool _Required;
        public bool Required { get { return _Required; } }
        private Decimal _MaxLength = 1023;
        public Decimal MaxLength { get { return _MaxLength; } }
        private bool _Expandable;
        public bool Expandable { get { return _Expandable; } }
        private bool _Soft;
        public bool Soft { get { return _Soft; } }
        [System.Management.Automation.HiddenAttribute]
        public void set_Properties(bool required, Decimal maxLength, bool expandable, bool soft)
        {
            _Required = required;
            _MaxLength = maxLength;
            _Expandable = expandable;
            _Soft = soft;
        }
        public TextDefinitionElement(string id, string registryPath, string registryValueName) : base(id, registryPath, registryValueName)
        {
        }
    }

    public sealed class MultiTextDefinitionElement : ValueDefinitionElementBase
    {
        public override ElementTypes ElementType { get { return ElementTypes.MultiText; } }
        private bool _Required;
        public bool Required { get { return _Required; } }
        private Decimal _MaxLength = 1023;
        public Decimal MaxLength { get { return _MaxLength; } }
        private Decimal _MaxStrings;
        public Decimal MaxStrings { get { return _MaxStrings; } }
        private bool _Soft;
        public bool Soft { get { return _Soft; } }
        [System.Management.Automation.HiddenAttribute]
        public void set_Properties(bool required, Decimal maxLength, Decimal maxStrings, bool soft)
        {
            _Required = required;
            _MaxLength = maxLength;
            _MaxStrings = maxStrings;
            _Soft = soft;
        }
        public MultiTextDefinitionElement(string id, string registryPath, string registryValueName) : base(id, registryPath, registryValueName)
        {
        }
    }

    public sealed class EnumValue
    {
        private ValueDefinition _Value;
        public ValueDefinition Value { get { return _Value; } }
        private ValueDefinitionList _ValueList;
        public ValueDefinitionList ValueList { get { return _ValueList; } internal set { _ValueList = value; } }
        public bool HasValueList { get { return (_ValueList != null && _ValueList.Items.Count > 0); } }
        public EnumValue(ValueDefinition value)
        {
            _Value = value;
        }
        public override string ToString()
        {
            return _Value.ToString();
        }
    }

    public sealed class EnumDefinitionElement : ValueDefinitionElementBase
    {
        public override ElementTypes ElementType { get { return ElementTypes.Enum; } }
        private bool _Required;
        public bool Required { get { return _Required; } }
        [System.Management.Automation.HiddenAttribute]
        public void set_Properties(bool required)
        {
            _Required = required;
        }
        private List<KeyValuePair<string, EnumValue>> _Enums = new List<KeyValuePair<string, EnumValue>>();
        public List<KeyValuePair<string, EnumValue>> Enums { get { return _Enums; } }
        [System.Management.Automation.HiddenAttribute]
        public void add_EnumsItem(string displayName, ValueDefinition value, ValueDefinitionList valueList)
        {
            EnumValue enumvalue = new EnumValue(value);
            if (valueList != null) 
            {
                enumvalue.ValueList = valueList;
            }
            _Enums.Add(new KeyValuePair<string, EnumValue>(displayName, enumvalue));
        }
        public EnumDefinitionElement(string id, string registryPath, string registryValueName) : base(id, registryPath, registryValueName)
        {
        }
    }

    public sealed class ListDefinitionElement : ValueDefinitionElementBase
    {
        public override ElementTypes ElementType { get { return ElementTypes.List; } }
        private string _ValuePrefix;
        public string ValuePrefix { get { return _ValuePrefix; } }
        private bool _Additive;
        public bool Additive { get { return _Additive; } }
        private bool _Expandable;
        public bool Expandable { get { return _Expandable; } }
        private bool _ExplicitValue;
        public bool ExplicitValue { get { return _ExplicitValue; } }
        private string _ClientExtension;
        public string ClientExtension { get { return _ClientExtension; } }
        [System.Management.Automation.HiddenAttribute]
        public void set_Properties(string valuePrefix, bool additive, bool expandable, bool explicitValue, string clientExtension)
        {
            _ValuePrefix = valuePrefix;
            _Additive = additive;
            _Expandable = expandable;
            _ExplicitValue = explicitValue;
            _ClientExtension = clientExtension;
        }
        public ListDefinitionElement(string id, string registryPath, string registryValueName) : base(id, registryPath, registryValueName)
        {
        }
    }

    public sealed class ValueDefinitionElements
    {
        private List<IValueDefinitionElement> _Items = new List<IValueDefinitionElement>();
        public List<IValueDefinitionElement> Items { get { return _Items; } }
    }

    public sealed class PolicyValueInfo
    {
        // Registry value information.
        private string _RegistryValueName;
        public string RegistryValueName { get { return _RegistryValueName; } }
        // single Enabled/Disabled value definitions.
        private ValueDefinition _EnabledValue;
        public ValueDefinition EnabledValue { get { return _EnabledValue; } }
        private ValueDefinition _DisabledValue;
        public ValueDefinition DisabledValue { get { return _DisabledValue; } }
        [System.Management.Automation.HiddenAttribute]
        public void set_RegistryValue(string valueName, ValueDefinition enabledValue, ValueDefinition disabledValue)
        {
            _RegistryValueName = valueName;
            _EnabledValue = enabledValue;
            _DisabledValue = disabledValue;
        }
        // list value definitions.
        private ValueDefinitionList _EnabledList;
        public ValueDefinitionList EnabledList { get { return _EnabledList; } }
        public bool HasEnabledList { get { return (_EnabledList != null && _EnabledList.Items.Count > 0); } }
        private ValueDefinitionList _DisabledList;
        public ValueDefinitionList DisabledList { get { return _DisabledList; } }
        public bool HasDisabledList { get { return (_DisabledList != null && _DisabledList.Items.Count > 0); } }
        [System.Management.Automation.HiddenAttribute]
        public void set_EnabledListValue(ValueDefinitionList list)
        {
            _EnabledList = list;
        }
        [System.Management.Automation.HiddenAttribute]
        public void set_DisabledListValue(ValueDefinitionList list)
        {
            _DisabledList = list;
        }
        // element value definition.
        private ValueDefinitionElements _Elements;
        public ValueDefinitionElements Elements { get { return _Elements; } }
        public bool HasElements { get { return (_Elements != null && _Elements.Items.Count > 0); } }
        [System.Management.Automation.HiddenAttribute]
        public void set_ElementsValue(ValueDefinitionElements elements)
        {
            _Elements = elements;
        }
    }
}