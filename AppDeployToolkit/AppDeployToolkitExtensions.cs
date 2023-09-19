// Version: 2023.04.05.01

using Microsoft.Win32.SafeHandles;
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Collections.Specialized;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.ComponentModel;
using System.IO.Pipes;
using System.Reflection;
using System.Runtime.CompilerServices;

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

        public static int StartPowershellScriptAndWaitForExitCode(string arguments)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = arguments,
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true,
                UseShellExecute = false
            };

            Process process = new Process();
            process.StartInfo = startInfo;
            process.Start();
            process.WaitForExit();
            return process.ExitCode;
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

public class SessionHelper
{
    internal const int ERROR_NOT_ALL_ASSIGNED = 1300;

    internal const uint INFINITE = 0xFFFFFFFF;

    internal const uint MAXIMUM_ALLOWED = 0x2000000;

    internal const int READ_CONTROL = 0x00020000;

    internal const int SE_PRIVILEGE_ENABLED = 0x0002;

    internal const string SE_TCB_NAME = "SeTcbPrivilege";

    internal const int STANDARD_RIGHTS_EXECUTE = READ_CONTROL;

    internal const int STANDARD_RIGHTS_READ = READ_CONTROL;

    internal const int STANDARD_RIGHTS_REQUIRED = 0x000F0000;

    internal const int STANDARD_RIGHTS_WRITE = READ_CONTROL;

    internal const uint TH32CS_SNAPPROCESS = 0x00000002;

    internal const int TOKEN_ADJUST_DEFAULT = 0x0080;

    internal const int TOKEN_ADJUST_GROUPS = 0x0040;

    internal const int TOKEN_ADJUST_PRIVILEGES = 0x0020;

    internal const int TOKEN_ADJUST_SESSIONID = 0x0100;

    internal const int TOKEN_ASSIGN_PRIMARY = 0x0001;

    internal const int TOKEN_DUPLICATE = 0x0002;

    internal const int TOKEN_IMPERSONATE = 0x0004;

    internal const int TOKEN_QUERY = 0x0008;

    internal const int TOKEN_QUERY_SOURCE = 0x0010;

    internal static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);

    internal static uint TOKEN_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE | TOKEN_IMPERSONATE | TOKEN_QUERY | TOKEN_QUERY_SOURCE | TOKEN_ADJUST_PRIVILEGES | TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT | TOKEN_ADJUST_SESSIONID);



    internal static STARTUPINFO StartupInfo;

    private static readonly FieldInfo ErrorField = typeof(Process).GetField("standardError",
        BindingFlags.Instance | BindingFlags.NonPublic);

    private static readonly FieldInfo InputField = typeof(Process).GetField("standardInput",
        BindingFlags.Instance | BindingFlags.NonPublic);

    private static readonly FieldInfo OutputField = typeof(Process).GetField("standardOutput",
        BindingFlags.Instance | BindingFlags.NonPublic);

    private static GCHandle _enviromentBlock;

    private static AnonymousPipeServerStream _errorStream;

    private static AnonymousPipeServerStream _inputStream;

    private static AnonymousPipeServerStream _outputStream;

    [Flags]
    internal enum ProcessCreationFlags : uint
    {
        CREATE_BREAKAWAY_FROM_JOB = 0x01000000,
        CREATE_DEFAULT_ERROR_MODE = 0x04000000,
        CREATE_NEW_CONSOLE = 0x00000010,
        CREATE_NEW_PROCESS_GROUP = 0x00000200,
        CREATE_NO_WINDOW = 0x08000000,
        CREATE_PROTECTED_PROCESS = 0x00040000,
        CREATE_PRESERVE_CODE_AUTHZ_LEVEL = 0x02000000,
        CREATE_SEPARATE_WOW_VDM = 0x00000800,
        CREATE_SHARED_WOW_VDM = 0x00001000,
        CREATE_SUSPENDED = 0x00000004,
        CREATE_UNICODE_ENVIRONMENT = 0x00000400,
        DEBUG_ONLY_THIS_PROCESS = 0x00000002,
        DEBUG_PROCESS = 0x00000001,
        DETACHED_PROCESS = 0x00000008,
        EXTENDED_STARTUPINFO_PRESENT = 0x00080000,
        INHERIT_PARENT_AFFINITY = 0x00010000,

        IDLE_PRIORITY_CLASS = 0x40,
        NORMAL_PRIORITY_CLASS = 0x20,
        HIGH_PRIORITY_CLASS = 0x80,
        REALTIME_PRIORITY_CLASS = 0x100,
    }

    internal enum SECURITY_IMPERSONATION_LEVEL
    {
        SecurityAnonymous = 0,
        SecurityIdentification = 1,
        SecurityImpersonation = 2,
        SecurityDelegation = 3
    }

    internal enum TOKEN_ELEVATION_TYPE
    {
        TokenElevationTypeDefault = 1,
        TokenElevationTypeFull,
        TokenElevationTypeLimited
    }

    internal enum TOKEN_INFORMATION_CLASS
    {
        TokenUser = 1,
        TokenGroups,
        TokenPrivileges,
        TokenOwner,
        TokenPrimaryGroup,
        TokenDefaultDacl,
        TokenSource,
        TokenType,
        TokenImpersonationLevel,
        TokenStatistics,
        TokenRestrictedSids,
        TokenSessionId,
        TokenGroupsAndPrivileges,
        TokenSessionReference,
        TokenSandBoxInert,
        TokenAuditPolicy,
        TokenOrigin,
        TokenElevationType,
        TokenLinkedToken,
        TokenElevation,
        TokenHasRestrictions,
        TokenAccessInformation,
        TokenVirtualizationAllowed,
        TokenVirtualizationEnabled,
        TokenIntegrityLevel,
        TokenUIAccess,
        TokenMandatoryPolicy,
        TokenLogonSid,
        MaxTokenInfoClass  // MaxTokenInfoClass should always be the last enum
    }

    internal enum TOKEN_TYPE
    {
        TokenPrimary = 1,
        TokenImpersonation = 2
    }

    internal enum WTSQueryUserTokenErrors
    {
        /// <summary>
        /// The caller does not have the SE_TCB_NAME privilege.
        /// </summary>
        ERROR_PRIVILEGE_NOT_HELD = 1314,

        /// <summary>
        /// One of the parameters to the function was incorrect; for example, the phToken parameter was passed a NULL parameter.
        /// </summary>
        ERROR_INVALID_PARAMETER = 87,

        /// <summary>
        /// The caller does not have the appropriate permissions to call this function.The caller must be running within the context of the LocalSystem account and have the SE_TCB_NAME privilege.
        /// </summary>
        ERROR_ACCESS_DENIED = 5,

        /// <summary>
        /// The token query is for a session that does not exist.
        /// </summary>
        ERROR_FILE_NOT_FOUND = 2,

        /// <summary>
        /// The token query is for a session in which no user is logged-on. This occurs, for example, when the session is in the idle state or SessionId is zero.
        /// </summary>
        ERROR_NO_TOKEN = 1008
    }

    [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetTokenInformation(
      IntPtr hToken,
      TOKEN_INFORMATION_CLASS tokenInfoClass,
      IntPtr pTokenInfo,
      Int32 tokenInfoLength,
      out Int32 returnLength);

    private static byte[] ToByteArray(StringDictionary sd, bool unicode)
    {
        string[] array = new string[sd.Count];
        sd.Keys.CopyTo(array, 0);
        string[] array2 = new string[sd.Count];
        sd.Values.CopyTo(array2, 0);
        Array.Sort(array, array2, StringComparer.OrdinalIgnoreCase);
        StringBuilder stringBuilder = new StringBuilder();
        for (int i = 0; i < sd.Count; i++)
        {
            stringBuilder.Append(array[i]);
            stringBuilder.Append('=');
            stringBuilder.Append(array2[i]);
            stringBuilder.Append('\0');
        }
        stringBuilder.Append('\0');
        byte[] bytes;
        if (unicode)
        {
            bytes = Encoding.Unicode.GetBytes(stringBuilder.ToString());
        }
        else
        {
            bytes = Encoding.Default.GetBytes(stringBuilder.ToString());
            if (bytes.Length > 65535)
            {
                throw new InvalidOperationException("Environment block too long, is " + bytes.Length + " long, it' longer than 65535 bytes.");
            }
        }
        return bytes;
    }

    private static IntPtr EnviromentBlock(ProcessStartInfo processStartInfo)
    {
        if (!_enviromentBlock.IsAllocated)
        {
            byte[] envBlock = ToByteArray(
                processStartInfo.EnvironmentVariables,
                Environment.OSVersion.Platform == PlatformID.Win32NT
            );
            _enviromentBlock = GCHandle.Alloc(envBlock, GCHandleType.Pinned);
        }
        return _enviromentBlock.AddrOfPinnedObject();
    }

    private static IntPtr QueryAndDuplicateUserToken(uint sessionId)
    {
        IntPtr currentToken;
        if (!WTSQueryUserToken(sessionId, out currentToken))
        {
            int err = Marshal.GetLastWin32Error();
            switch ((WTSQueryUserTokenErrors)err)
            {
                case WTSQueryUserTokenErrors.ERROR_FILE_NOT_FOUND:
                    throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'Session does not exist'");
                case WTSQueryUserTokenErrors.ERROR_ACCESS_DENIED:
                    throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'Must be running as LocalSystem account and must have the SE_TCB_NAME privilege.'");

                case WTSQueryUserTokenErrors.ERROR_INVALID_PARAMETER:
                    throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'Invalid parameter'");
                case WTSQueryUserTokenErrors.ERROR_PRIVILEGE_NOT_HELD:
                    throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'SE_TCB_NAME privilege missing'");

                case WTSQueryUserTokenErrors.ERROR_NO_TOKEN:
                    throw CreateWin32ExceptionWithDescription("WTSQueryUserToken", "'No user logged-on for this session id'");
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        IntPtr primaryToken;
        if (!DuplicateTokenEx(currentToken, TOKEN_ASSIGN_PRIMARY | TOKEN_ALL_ACCESS, IntPtr.Zero,
            SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation, TOKEN_TYPE.TokenPrimary, out primaryToken))
        {
            throw SessionHelper.CreateWin32Exception("DuplicateTokenEx");
        }

        return primaryToken;
    }

    public static int StartProcessAndWaitForExitCode(string arguments, List<uint> sessionIds)
   {
       List<IntPtr> primaryTokens = new List<IntPtr>();
       foreach (var sessionId in sessionIds)
       {
           primaryTokens.Add(Elevate(QueryAndDuplicateUserToken(sessionId)));
       }
       try
       {
           return CreateProcessAndWaitForExit(primaryTokens, arguments);
       }
       finally
       {
           foreach (var primaryToken in primaryTokens)
           {
               CloseHandle(primaryToken);
           }
       }
   }


    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges,
        ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    internal static extern bool CloseHandle(IntPtr hSnapshot);

    [DllImport("advapi32.dll", EntryPoint = "CreateProcessAsUser", SetLastError = true, CharSet = CharSet.Ansi,
       CallingConvention = CallingConvention.StdCall)]
    internal static extern bool CreateProcessAsUser(IntPtr hToken, String lpApplicationName, String lpCommandLine,
       SECURITY_ATTRIBUTES lpProcessAttributes,
       SECURITY_ATTRIBUTES lpThreadAttributes, bool bInheritHandle, uint dwCreationFlags, IntPtr lpEnvironment,
       String lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    internal static Win32Exception CreateWin32Exception(string nativeFunction,
       [CallerMemberName] string callerFunction = null)
    {
        var err = Marshal.GetLastWin32Error();
        throw new Win32Exception("Error " + err + " from " + nativeFunction + " called by " + callerFunction, new Win32Exception(err));
    }

    internal static Win32Exception CreateWin32ExceptionWithDescription(string nativeFunction, string description,
      [CallerMemberName] string callerFunction = null)
    {
        var err = Marshal.GetLastWin32Error();
        throw new Win32Exception("Error " + err + ": " + description + " from " + nativeFunction + " called by " + callerFunction, new Win32Exception(err));
    }

    [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    internal static extern bool DuplicateTokenEx(IntPtr existingToken, uint desiredAccess, IntPtr tokenAttributes, SECURITY_IMPERSONATION_LEVEL impersonationLevel, TOKEN_TYPE tokenType, out IntPtr newToken);

    internal static IntPtr Elevate(IntPtr hToken)
    {
        if (hToken == IntPtr.Zero)
            throw new ArgumentOutOfRangeException("hToken");

        IntPtr pToken = hToken;
        IntPtr pElevationType = IntPtr.Zero;
        int cbSize = sizeof(TOKEN_ELEVATION_TYPE);
        pElevationType = Marshal.AllocHGlobal(cbSize);
        if (pElevationType == IntPtr.Zero)
            throw new Win32Exception();

        if (!GetTokenInformation(hToken,
            TOKEN_INFORMATION_CLASS.TokenElevationType, pElevationType,
            cbSize, out cbSize))
            throw new Win32Exception();

        TOKEN_ELEVATION_TYPE elevType = (TOKEN_ELEVATION_TYPE)
            Marshal.ReadInt32(pElevationType);

        if (elevType == TOKEN_ELEVATION_TYPE.TokenElevationTypeLimited)
        {
            IntPtr pLinkedToken = IntPtr.Zero;
            cbSize = IntPtr.Size;
            pLinkedToken = Marshal.AllocHGlobal(cbSize);

            if (pLinkedToken == IntPtr.Zero)
                throw new Win32Exception();

            if (!GetTokenInformation(hToken,
                TOKEN_INFORMATION_CLASS.TokenLinkedToken, pLinkedToken,
                cbSize, out cbSize))
                throw new Win32Exception();

            pToken = Marshal.ReadIntPtr(pLinkedToken);
            CloseHandle(hToken);
        }

        TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
        LUID luid = new LUID();

        if (!LookupPrivilegeValue(IntPtr.Zero, SE_TCB_NAME, ref luid))
            throw SessionHelper.CreateWin32Exception("LookupPrivilegeValue");

        tp.PrivilegeCount = 1;
        tp.Privileges = new int[3];
        tp.Privileges[2] = SE_PRIVILEGE_ENABLED;
        tp.Privileges[1] = luid.HighPart;
        tp.Privileges[0] = luid.LowPart;

        if (!AdjustTokenPrivileges(pToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero))
        {
            int err = Marshal.GetLastWin32Error();

            var errStr = string.Format((err == ERROR_NOT_ALL_ASSIGNED)
                ? "CreateProcessInConsoleSession AdjustTokenPrivileges error: {0} Token does not have the privilege."
                : "CreateProcessInConsoleSession AdjustTokenPrivileges error: {0}", err);
            throw new Win32Exception(err, errStr);
        }

        return pToken;
    }

    [DllImport("kernel32.dll")]
    internal static extern bool GetExitCodeProcess(IntPtr hProcess, out int lpExitCode);

    [DllImport("kernel32.dll", SetLastError = true)]
    internal static extern IntPtr GetStdHandle(int nStdHandle);

     [DllImport("kernel32.dll")]
   internal static extern int WaitForMultipleObjects(int nCount, IntPtr[] lpHandles, bool bWaitAll, uint dwMilliseconds);

    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(IntPtr lpSystemName, string lpname,
      [MarshalAs(UnmanagedType.Struct)] ref LUID lpLuid);

    [DllImport("Wtsapi32.dll", SetLastError = true)]
    internal static extern bool WTSQueryUserToken(uint sessionId, out IntPtr phToken);

 


    internal static int CreateProcessAndWaitForExit(List<IntPtr> hTokens, string arguments)
    {
        var processes = new List<IntPtr>();
        foreach (var hToken in hTokens)
        {
            SECURITY_ATTRIBUTES securityAttributes = SECURITY_ATTRIBUTES.Default;
            var processStartInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = arguments,
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true,
                UseShellExecute = false
            };
            StartupInfo = BuildStartupInfo(processStartInfo);

            PROCESS_INFORMATION pi;
            // Launch the process in the client's logon session.
            var bResult = CreateProcessAsUser(hToken, // client's access token
                null, // file to execute
                CreateCommandLine("powershell.exe", arguments), // command line
                securityAttributes, // pointer to process SECURITY_ATTRIBUTES
                securityAttributes, // pointer to thread SECURITY_ATTRIBUTES
                true, // handles inheritable ?
                CreationFlags(ProcessCreationFlags.CREATE_NO_WINDOW),
                EnviromentBlock(processStartInfo), // pointer to new environment block
                WorkingDirectory(processStartInfo), // name of current directory
                ref StartupInfo, // pointer to STARTUPINFO structure
                out pi // receives information about new process
            );
            // End impersonation of client.
            if (!bResult)
            {
                throw SessionHelper.CreateWin32Exception("CreateProcessAsUser");
            }

            var pr = Process.GetProcessById((int)pi.dwProcessId);
            if (processStartInfo.RedirectStandardInput)
            {
                InputField.SetValue(pr, new StreamWriter(_inputStream, Console.InputEncoding, 4096) { AutoFlush = true });
            }
            if (processStartInfo.RedirectStandardOutput)
                OutputField.SetValue(pr, new StreamReader(_outputStream, processStartInfo.StandardOutputEncoding ?? Console.OutputEncoding, true, 4096));
            if (processStartInfo.RedirectStandardError)
                ErrorField.SetValue(pr, new StreamReader(_errorStream, processStartInfo.StandardErrorEncoding ?? Console.OutputEncoding, true, 4096));

            processes.Add(pi.hProcess);
        }
        int index = WaitForMultipleObjects(hTokens.Count, processes.ToArray(), false, INFINITE);

        int exitCode = 1618;

        if (index >= 0 && index < hTokens.Count)
        {
            GetExitCodeProcess(processes[index], out exitCode);
        }
        
        return exitCode;

    }

    internal static uint CreationFlags(ProcessCreationFlags flags)
    {
        if (Environment.OSVersion.Platform == PlatformID.Win32NT)
            flags |= ProcessCreationFlags.CREATE_UNICODE_ENVIRONMENT;
        return (uint)flags;
    }

    internal static string WorkingDirectory(ProcessStartInfo processStartInfo)
    {
        return !string.IsNullOrEmpty(processStartInfo.WorkingDirectory) ?
        processStartInfo.WorkingDirectory :
        Environment.CurrentDirectory;
    }

    private static string CreateCommandLine(string processPath, string arguments)
    {
        string command = processPath.StartsWith("\"") ? processPath : "\"" + processPath + "\"";
        if (!string.IsNullOrEmpty(arguments))
        {
            command += " " + arguments;
        }
        return command;
    }

    private static STARTUPINFO BuildStartupInfo(ProcessStartInfo startInfo)
    {
        StartupInfo = new STARTUPINFO
        {
            cb = Marshal.SizeOf(typeof(STARTUPINFO)),
            hStdInput = new SafeFileHandle(IntPtr.Zero, false),
            hStdOutput = new SafeFileHandle(IntPtr.Zero, false),
            hStdError = new SafeFileHandle(IntPtr.Zero, false),
        };

        if (startInfo.RedirectStandardInput || startInfo.RedirectStandardOutput || startInfo.RedirectStandardError)
        {
            if (startInfo.RedirectStandardInput)
            {
                _inputStream = new AnonymousPipeServerStream(PipeDirection.Out, HandleInheritability.Inheritable);
                StartupInfo.hStdInput = _inputStream.ClientSafePipeHandle;
            }
            else
                StartupInfo.hStdInput = new SafeFileHandle(GetStdHandle(-10), false);

            if (startInfo.RedirectStandardOutput)
            {
                _outputStream = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                StartupInfo.hStdOutput = _outputStream.ClientSafePipeHandle;
            }
            else
                StartupInfo.hStdOutput = new SafeFileHandle(GetStdHandle(-11), false);

            if (startInfo.RedirectStandardError)
            {
                _errorStream = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                StartupInfo.hStdError = _errorStream.ClientSafePipeHandle;
            }
            else
                StartupInfo.hStdError = new SafeFileHandle(GetStdHandle(-12), false);
            StartupInfo.dwFlags = 256;
        }
        return StartupInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct LUID
    {
        public int LowPart;
        public int HighPart;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct PROCESS_INFORMATION
    {
        public IntPtr hProcess;
        public IntPtr hThread;
        public uint dwProcessId;
        public uint dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct STARTUPINFO
    {
        public int cb;
        public String lpReserved;
        public String lpDesktop;
        public String lpTitle;
        public uint dwX;
        public uint dwY;
        public uint dwXSize;
        public uint dwYSize;
        public uint dwXCountChars;
        public uint dwYCountChars;
        public uint dwFillAttribute;
        public uint dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2;
        public SafeHandleZeroOrMinusOneIsInvalid hStdInput;
        public SafeHandleZeroOrMinusOneIsInvalid hStdOutput;
        public SafeHandleZeroOrMinusOneIsInvalid hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct TOKEN_PRIVILEGES
    {
        public int PrivilegeCount;

        //LUID_AND_ATRIBUTES
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public int[] Privileges;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal sealed class SECURITY_ATTRIBUTES
    {
        public int Length;
        public IntPtr lpSecurityDescriptor;
        public bool bInheritHandle;

        public SECURITY_ATTRIBUTES()
        {
            Length = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
        }

        internal static readonly SECURITY_ATTRIBUTES Default = new SECURITY_ATTRIBUTES();
    }
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