// Version: 2023.04.05.01

using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace PSADTNXT
{
    public class Extensions
	{
        public static ProcessIdentity GetProcessIdentity(int processId)
        {
            var processHandle = IntPtr.Zero;
            WindowsIdentity wi = null;
            try
            {
                var process = Process.GetProcessById(processId);
                OpenProcessToken(process.Handle, 8, out processHandle);
                wi = new WindowsIdentity(processHandle);
                return new ProcessIdentity(wi);
            }
            catch
            {
                throw;
            }
            finally
            {
                if (wi != null)
                {
                    wi.Dispose();
                }

                if (processHandle != IntPtr.Zero)
                {
                    CloseHandle(processHandle);
                }
            }
        }

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool CloseHandle(IntPtr hObject);

        public static String GetEncoding(string filename)
        {
            // Read the BOM
            var bom = new byte[4];
            using (var file = new FileStream(filename, FileMode.Open, FileAccess.Read))
            {
                file.Read(bom, 0, 4);
            }
            // Analyze the BOM
            if (bom[0] == 0x2b && bom[1] == 0x2f && bom[2] == 0x76) return "UTF7";
            if (bom[0] == 0xef && bom[1] == 0xbb && bom[2] == 0xbf) return "UTF8withBOM";
            if (bom[0] == 0xff && bom[1] == 0xfe && bom[2] == 0 && bom[3] == 0) return "UTF32"; //UTF-32LE
            if (bom[0] == 0xff && bom[1] == 0xfe) return "Unicode"; //UTF-16LE
            if (bom[0] == 0xfe && bom[1] == 0xff) return "BigEndianUnicode"; //UTF-16BE
            if (bom[0] == 0 && bom[1] == 0 && bom[2] == 0xfe && bom[3] == 0xff) return "BigEndianUnicode";  //UTF-32BE
            // We actually have no idea what the encoding is if we reach this point, so
            // you may wish to return null instead of defaulting to ASCII
            return null;
        }
	}

    public class ProcessIdentity
    {
        public ProcessIdentity(WindowsIdentity identity)
        {
            Name = identity.Name;
            SID = identity.Owner.Value;
            IsSystem = identity.IsSystem;
        }

        public string Name { get; private set; }
        public string SID { get; private set; }
        public bool IsSystem { get; private set; }
    }

    public enum DriveType
    {
        Unknown = 0,
        NoRootDirectory = 1,
        Removable = 2,
        Local = 3,
        Network = 4,
        Compact = 5,
        Ram = 6
    }

    public enum VersionCompareResult
    {
        Equal = 1,
        Update = 2,
        Downgrade = 3
    }
    
    public enum ContinueType {
        Abort = 0,
        Continue = 1
    }

    public class NxtApplicationResult
    {
        public bool? Success { get; set; }
        public int ApplicationExitCode { get; set; }
        public int MainExitCode { get; set; }
        public string ErrorMessage { get; set; }
        public string ErrorMessagePsadt { get; set; }
    }

    public class NxtDisplayVersionResult
    {
        public bool UninstallKeyExists { get; set; }
        public string DisplayVersion { get; set; }
    }

    public class NxtRegisteredApplication
    {
        public string PackageGuid { get; set; }
        public string ProductGuid { get; set; }
        public bool Installed { get; set; }
    }

    public class NxtIniFile
    {
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
        public static extern int GetPrivateProfileString(string lpAppName, string lpKeyName, string lpDefault, StringBuilder lpReturnedString, int nSize, string lpFileName);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = false)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool WritePrivateProfileString(string lpAppName, string lpKeyName, string lpString, string lpFileName);

        public static void RemoveIniValue(string section, string key, string filepath)
        {
            WritePrivateProfileString(section, key, null, filepath);
        }
    }

    public class XmlNodeModel
    {
        private readonly Dictionary<string, string> _attributes;

        public XmlNodeModel()
        {
            _attributes = new Dictionary<string, string>();
        }

        public IReadOnlyDictionary<string, string> Attributes { get { return _attributes; } }

        public XmlNodeModel Child { get; set; }
        public string Name { get; set; }
        public string Value { get; set; }

        public void AddAttribute(string key, string value)
        {
            if (!_attributes.ContainsKey(key))
            {
                _attributes.Add(key, value);
                return;
            }
            _attributes[key] = value;
        }

        public void RemoveAttribute(string key)
        {
            if (_attributes.ContainsKey(key))
            {
                _attributes.Remove(key);
            }
        }
    }
}