// Date Modified: 10.08.2022
// Version Number: 0.1.0

using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Collections.Generic;
using System.Linq;

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
        Removeable = 2,
        Local = 3,
        Network = 4,
        Compact = 5,
        Ram = 6
    }

    public class VersionPartInfo
    {
        public VersionPartInfo(char value)
        {
            Value = value;
            AsciiValue = System.Text.Encoding.ASCII.GetBytes(new char[] { value }).FirstOrDefault();
        }

        public char Value { get; private set; }
        public byte AsciiValue { get; private set; }
    }

    public class VersionKeyValuePair
    {
        public VersionKeyValuePair(string key, VersionPartInfo[] value)
        {
            Key = key;
            Value = value.ToList();
        }

        public string Key { get; private set; }
        public List<VersionPartInfo> Value { get; private set; }
    }

    public enum VersionCompareResult
    {
        Equal = 1,
        Update = 2,
        Downgrade = 3
    }
}