using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("Easy WinGet Plus")]
[assembly: AssemblyDescription("A portable graphical interface for Windows Package Manager")]
[assembly: AssemblyCompany("廖阿輝")]
[assembly: AssemblyProduct("Easy WinGet Plus")]
[assembly: AssemblyCopyright("Copyright © 2026 廖阿輝")]
[assembly: AssemblyVersion("0.1.0.0")]
[assembly: AssemblyFileVersion("0.1.0.0")]

internal static class Program
{
    private const string Version = "0.1.0";
    private const string ResourceName = "EasyWinGetPlus.ps1";

    [STAThread]
    private static void Main()
    {
        try
        {
            string executableDirectory = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
            string runtimeDirectory = Path.Combine(Path.GetTempPath(), "EasyWinGetPlus", Version);
            string scriptPath = Path.Combine(runtimeDirectory, ResourceName);
            Directory.CreateDirectory(runtimeDirectory);

            using (Stream resource = Assembly.GetExecutingAssembly().GetManifestResourceStream(ResourceName))
            {
                if (resource == null)
                    throw new InvalidOperationException("The embedded application script could not be found.");

                using (FileStream output = new FileStream(scriptPath, FileMode.Create, FileAccess.Write, FileShare.Read))
                    resource.CopyTo(output);
            }

            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File \"" + scriptPath + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden,
                WorkingDirectory = executableDirectory
            };
            startInfo.EnvironmentVariables["EASYWINGETPLUS_HOME"] = executableDirectory;

            Process process = Process.Start(startInfo);
            if (process == null)
                throw new InvalidOperationException("Windows PowerShell could not be started.");
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                "Easy WinGet Plus could not start.\n\n" + ex.Message,
                "Easy WinGet Plus",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }
}
