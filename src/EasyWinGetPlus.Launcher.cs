using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("Easy WinGet Plus")]
[assembly: AssemblyDescription("A portable graphical interface for Windows Package Manager")]
[assembly: AssemblyCompany("廖阿輝")]
[assembly: AssemblyProduct("Easy WinGet Plus")]
[assembly: AssemblyCopyright("Copyright © 2026 廖阿輝")]
[assembly: AssemblyVersion("0.1.4.0")]
[assembly: AssemblyFileVersion("0.1.4.0")]

internal static class Program
{
    private const string Version = "0.1.4";
    private const string ResourceName = "EasyWinGetPlus.ps1";

    private static void ExtractResource(string resourceName, string destinationPath)
    {
        using (Stream resource = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName))
        {
            if (resource == null)
                throw new InvalidOperationException("The embedded resource could not be found: " + resourceName);

            using (FileStream output = new FileStream(destinationPath, FileMode.Create, FileAccess.Write, FileShare.Read))
                resource.CopyTo(output);
        }
    }

    private static string CreateDiagnosticLog(string details)
    {
        string logDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "EasyWinGetPlus",
            "Logs");

        try
        {
            Directory.CreateDirectory(logDirectory);
        }
        catch
        {
            logDirectory = Path.Combine(Path.GetTempPath(), "EasyWinGetPlus", "Logs");
            Directory.CreateDirectory(logDirectory);
        }

        string logPath = Path.Combine(
            logDirectory,
            "startup-" + DateTime.Now.ToString("yyyyMMdd-HHmmss-fff") + ".log");

        StringBuilder report = new StringBuilder();
        report.AppendLine("Easy WinGet Plus startup diagnostic");
        report.AppendLine("Version: " + Version);
        report.AppendLine("Time: " + DateTime.Now.ToString("O"));
        report.AppendLine("Windows: " + Environment.OSVersion);
        report.AppendLine(".NET Framework runtime: " + Environment.Version);
        report.AppendLine("Executable: " + Application.ExecutablePath);
        report.AppendLine();
        report.AppendLine(details);
        File.WriteAllText(logPath, report.ToString(), Encoding.UTF8);
        return logPath;
    }

    private static void ShowStartupFailure(string summary, string details)
    {
        string logPath = null;
        try
        {
            logPath = CreateDiagnosticLog(details);
        }
        catch
        {
            // A visible error is still useful when logging itself is blocked.
        }

        string message =
            "Easy WinGet Plus 無法啟動。\n" + summary +
            "\n\nEasy WinGet Plus could not start.\n" + summary;

        if (!String.IsNullOrWhiteSpace(details))
        {
            string visibleDetails = details.Trim();
            if (visibleDetails.Length > 1800)
                visibleDetails = visibleDetails.Substring(visibleDetails.Length - 1800);
            message += "\n\n錯誤資訊 / Error details:\n" + visibleDetails;
        }

        if (!String.IsNullOrWhiteSpace(logPath))
            message += "\n\n診斷紀錄 / Diagnostic log:\n" + logPath;

        MessageBox.Show(
            message,
            "Easy WinGet Plus",
            MessageBoxButtons.OK,
            MessageBoxIcon.Error);
    }

    [STAThread]
    private static void Main()
    {
        try
        {
            bool createdNew;
            using (Mutex instanceMutex = new Mutex(true, @"Local\EasyWinGetPlus.LauncherInstance.8F5276E2", out createdNew))
            {
                if (!createdNew)
                {
                    MessageBox.Show(
                        "Easy WinGet Plus 已經在執行中，無法重複開啟。\n\nEasy WinGet Plus is already running and cannot be opened again.",
                        "Easy WinGet Plus",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information);
                    return;
                }

                string executableDirectory = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
                string runtimeDirectory = Path.Combine(Path.GetTempPath(), "EasyWinGetPlus", Version);
                string scriptPath = Path.Combine(runtimeDirectory, ResourceName);
                string powerShellPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.System),
                    "WindowsPowerShell",
                    "v1.0",
                    "powershell.exe");

                if (!File.Exists(powerShellPath))
                    throw new FileNotFoundException("Windows PowerShell 5.1 could not be found.", powerShellPath);

                Directory.CreateDirectory(runtimeDirectory);

                ExtractResource(ResourceName, scriptPath);

                ProcessStartInfo startInfo = new ProcessStartInfo
                {
                    FileName = powerShellPath,
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File \"" + scriptPath + "\"",
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    WorkingDirectory = executableDirectory,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                startInfo.EnvironmentVariables["EASYWINGETPLUS_HOME"] = executableDirectory;
                startInfo.EnvironmentVariables["EASYWINGETPLUS_EXECUTABLE"] = Application.ExecutablePath;
                startInfo.EnvironmentVariables["EASYWINGETPLUS_LAUNCHER_PID"] = Process.GetCurrentProcess().Id.ToString();

                using (Process process = Process.Start(startInfo))
                {
                    if (process == null)
                        throw new InvalidOperationException("Windows PowerShell could not be started.");

                    StringBuilder output = new StringBuilder();
                    StringBuilder error = new StringBuilder();
                    process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs eventArgs)
                    {
                        if (eventArgs.Data != null) output.AppendLine(eventArgs.Data);
                    };
                    process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs eventArgs)
                    {
                        if (eventArgs.Data != null) error.AppendLine(eventArgs.Data);
                    };
                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();
                    process.WaitForExit();

                    if (process.ExitCode != 0)
                    {
                        string diagnosticDetails =
                            "PowerShell: " + powerShellPath + Environment.NewLine +
                            "Script: " + scriptPath + Environment.NewLine +
                            "Exit code: " + process.ExitCode + Environment.NewLine +
                            Environment.NewLine + "Standard error:" + Environment.NewLine + error +
                            Environment.NewLine + "Standard output:" + Environment.NewLine + output;
                        ShowStartupFailure(
                            "Windows PowerShell 結束代碼 / exit code: " + process.ExitCode,
                            diagnosticDetails);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            ShowStartupFailure(ex.Message, ex.ToString());
        }
    }
}
