using System;
using System.ComponentModel;
using System.IO;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Text;
public static class PgOfflineRecovery {
 [StructLayout(LayoutKind.Sequential)] struct Sid {public IntPtr Value;public uint Attributes;}
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] struct Startup {
 public uint cb;public string reserved,desktop,title;public uint x,y,xsize,ysize,xchars,ychars,fill,flags;public ushort show,reserved2;public IntPtr reservedPtr,input,output,error;
 }
 [StructLayout(LayoutKind.Sequential)] struct Info {public IntPtr process,thread;public uint pid,tid;}
 [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
 [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
 [DllImport("kernel32.dll")] static extern uint WaitForSingleObject(IntPtr handle,uint ms);
 [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetExitCodeProcess(IntPtr process,out uint code);
 [DllImport("kernel32.dll")] static extern IntPtr LocalFree(IntPtr ptr);
 [DllImport("advapi32.dll",SetLastError=true)] static extern bool OpenProcessToken(IntPtr process,uint access,out IntPtr token);
 [DllImport("advapi32.dll",SetLastError=true,CharSet=CharSet.Unicode)] static extern bool ConvertStringSidToSid(string sid,out IntPtr ptr);
 [DllImport("advapi32.dll",SetLastError=true)] static extern bool CreateRestrictedToken(IntPtr token,uint flags,uint count,Sid[] disabled,uint privilegeCount,IntPtr privileges,uint restrictedCount,IntPtr restricted,out IntPtr result);
 [DllImport("advapi32.dll",SetLastError=true,CharSet=CharSet.Unicode)] static extern bool CreateProcessAsUser(IntPtr token,string application,StringBuilder command,IntPtr processAttributes,IntPtr threadAttributes,bool inherit,uint flags,IntPtr environment,string directory,ref Startup startup,out Info info);
 static void Check(bool ok){if(!ok)throw new Win32Exception(Marshal.GetLastWin32Error());}
 public static void Run(string binary,string data,string sql) {
  IntPtr original=IntPtr.Zero,restricted=IntPtr.Zero,a=IntPtr.Zero,b=IntPtr.Zero;
  Info pi=new Info();
  using(var input=new AnonymousPipeServerStream(PipeDirection.Out,HandleInheritability.Inheritable))
  using(var output=new AnonymousPipeServerStream(PipeDirection.In,HandleInheritability.Inheritable))
  using(var error=new AnonymousPipeServerStream(PipeDirection.In,HandleInheritability.Inheritable)){
   try {
    Check(OpenProcessToken(GetCurrentProcess(),0xF01FF,out original));
    Check(ConvertStringSidToSid("S-1-5-32-544",out a));
    Check(ConvertStringSidToSid("S-1-5-32-547",out b));
    Check(CreateRestrictedToken(original,1,2,new Sid[]{new Sid{Value=a},new Sid{Value=b}},0,IntPtr.Zero,0,IntPtr.Zero,out restricted));
    var si=new Startup();si.cb=(uint)Marshal.SizeOf(typeof(Startup));si.flags=0x100;
    si.input=input.ClientSafePipeHandle.DangerousGetHandle();
    si.output=output.ClientSafePipeHandle.DangerousGetHandle();
    si.error=error.ClientSafePipeHandle.DangerousGetHandle();
    var command=new StringBuilder("\""+binary+"\" --single -D \""+data+"\" -c log_statement=none -c log_min_error_statement=panic postgres");
    Check(CreateProcessAsUser(restricted,binary,command,IntPtr.Zero,IntPtr.Zero,true,0,IntPtr.Zero,null,ref si,out pi));
    input.DisposeLocalCopyOfClientHandle();output.DisposeLocalCopyOfClientHandle();error.DisposeLocalCopyOfClientHandle();
    using(var outReader=new StreamReader(output))
    using(var errReader=new StreamReader(error)){
     var outTask=outReader.ReadToEndAsync();var errTask=errReader.ReadToEndAsync();
     using(var writer=new StreamWriter(input,new UTF8Encoding(false))){writer.WriteLine(sql);}
     // A single-user backend must finish before the normal service can restart.
     WaitForSingleObject(pi.process,0xFFFFFFFF);
     uint code;Check(GetExitCodeProcess(pi.process,out code));
     string stdout=outTask.GetAwaiter().GetResult(),stderr=errTask.GetAwaiter().GetResult();
     if(code!=0||stderr.IndexOf("ERROR:",StringComparison.OrdinalIgnoreCase)>=0||stderr.IndexOf("FATAL:",StringComparison.OrdinalIgnoreCase)>=0)
      throw new InvalidOperationException("Recuperacion offline fallida. Verifica permisos de la carpeta de datos y que el servidor estaba detenido. No se muestran sentencias ni secretos.");
    }
   } finally{
    if(pi.thread!=IntPtr.Zero)CloseHandle(pi.thread);if(pi.process!=IntPtr.Zero)CloseHandle(pi.process);
    if(original!=IntPtr.Zero)CloseHandle(original);if(restricted!=IntPtr.Zero)CloseHandle(restricted);
    if(a!=IntPtr.Zero)LocalFree(a);if(b!=IntPtr.Zero)LocalFree(b);
   }
  }
 }
}
