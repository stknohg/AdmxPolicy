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
        public string DisplayName { get { return _DisplayName; } set { _DisplayName = value; } }
        private string _Description;
        public string Description { get { return _Description; } set { _Description = value; } }
        private Dictionary<string, string> _Strings = new Dictionary<string, string>();
        public Dictionary<string, string> Strings { get { return _Strings; } }
        private Dictionary<string, string> _Windows = new Dictionary<string, string>();
        public Dictionary<string, string> Windows { get { return _Windows; } }
    }

    public sealed class AdmxFileInfo
    {
        private string _Name;
        public string Name { get { return _Name; } set { _Name = value; } }
        private string _DisplayName;
        public string DisplayName { get { return _DisplayName; } set { _DisplayName = value; } }
        private string _Description;
        public string Description { get { return _Description; } set { _Description = value; } }
        private List<CategoryInfo> _Categories = new List<CategoryInfo>();
        public List<CategoryInfo> Categories { get { return _Categories; } }
        public override string ToString()
        {
            return _Name;
        }
    }

    public sealed class CategoryInfo
    {
        private string _Name;
        public string Name { get { return _Name; } set { _Name = value; } }
        private string _DisplayName;
        public string DisplayName { get { return _DisplayName; } set { _DisplayName = value; } }
    }

    public sealed class PolicyInfo
    {
        private AdmxFileInfo _FileInfo;
        public AdmxFileInfo FileInfo { get { return _FileInfo; } set { _FileInfo = value; } }
        private string _Name;
        public string Name { get { return _Name; } set { _Name = value; } }
        private string _DisplayName;
        public string DisplayName { get { return _DisplayName; } set { _DisplayName = value; } }
        private string _ExplainText;
        public string ExplainText { get { return _ExplainText; } set { _ExplainText = value; } }
        private RegistryTypes _RegistryType;
        public RegistryTypes RegistryType { get { return _RegistryType; } set { _RegistryType = value; } }
        public string[] RegistryDrives
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
        public string RegistryPath { get { return _RegistryPath; } set { _RegistryPath = value; } }
        private PolicyValueInfo _ValueInfo;
        public PolicyValueInfo ValueInfo { get { return _ValueInfo; } set { _ValueInfo = value; } }
    }

    public enum ValueTypes
    {
        Unknown = 0,
        Delete,
        Decimal,
        LongDecimal,
        String
    }

    public sealed class ValueDefinition
    {
        private ValueTypes _Type;
        public ValueTypes Type { get { return _Type; } }
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
        // TODO : implement ValueList, Element type definitions.
        // element value definition.
        private bool _HasElement;
        public bool HasElement { get { return _HasElement; } }
        [System.Management.Automation.HiddenAttribute]
        public void _set_HasElement(bool element)
        {
            // ! Temporary implementation
            _HasElement = element;
        }
    }
}