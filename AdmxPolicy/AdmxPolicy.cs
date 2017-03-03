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
        private string[] _RegistryPath;
        public string[] RegistryPath { get { return _RegistryPath; } set { _RegistryPath = value; } }
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
        // TODO : implement ValueList, Element type definitions.
        // list value definitions.
        private bool _HasEnabledList;
        public bool HasEnabledList { get { return _HasEnabledList; } }
        private bool _HasDisabledList;
        public bool HasDisabledList { get { return _HasDisabledList; } }
        [System.Management.Automation.HiddenAttribute]
        public void _set_HasList(bool enabledList, bool disabledList)
        {
            // ! Temporary implementation
            _HasEnabledList = enabledList;
            _HasDisabledList = disabledList;
        }
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