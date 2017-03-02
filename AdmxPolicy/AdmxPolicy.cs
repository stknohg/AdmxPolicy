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
    }
}