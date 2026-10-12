param(
    [Parameter(Mandatory = $true)][int]$ProcessId,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [int]$SettleMs = 500
)

$drawing = [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
if (-not $drawing) { throw "System.Drawing not available" }

$code = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Drawing.Imaging;

public static class ProcessWindowCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, int nFlags);

    public static IntPtr FindTopWindow(int pid) {
        var proc = Process.GetProcessById(pid);
        proc.Refresh();
        return proc.MainWindowHandle;
    }

    public static void Save(IntPtr hwnd, string path) {
        if (hwnd == IntPtr.Zero) throw new InvalidOperationException("Window handle is zero.");
        ShowWindow(hwnd, 9);
        SetForegroundWindow(hwnd);
        System.Threading.Thread.Sleep(250);
        RECT r;
        if (!GetWindowRect(hwnd, out r)) throw new InvalidOperationException("GetWindowRect failed.");
        int w = Math.Max(1, r.Right - r.Left);
        int h = Math.Max(1, r.Bottom - r.Top);
        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(bmp)) {
            IntPtr hdc = g.GetHdc();
            bool ok = PrintWindow(hwnd, hdc, 2);
            g.ReleaseHdc(hdc);
            if (!ok) {
                g.CopyFromScreen(r.Left, r.Top, 0, 0, new Size(w, h), CopyPixelOperation.SourceCopy);
            }
            var dir = System.IO.Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir)) System.IO.Directory.CreateDirectory(dir);
            bmp.Save(path, ImageFormat.Png);
        }
    }
}
'@

if (-not ("ProcessWindowCapture" -as [type])) {
    Add-Type -ReferencedAssemblies @("System.dll", "System.Drawing.dll") -TypeDefinition $code -Language CSharp
}

Start-Sleep -Milliseconds $SettleMs
$hwnd = [IntPtr]::Zero
for ($i = 0; $i -lt 30; $i++) {
    $hwnd = [ProcessWindowCapture]::FindTopWindow($ProcessId)
    if ($hwnd -ne [IntPtr]::Zero) { break }
    Start-Sleep -Milliseconds 200
}
if ($hwnd -eq [IntPtr]::Zero) { throw "Could not find main window for PID $ProcessId" }
[ProcessWindowCapture]::Save($hwnd, $OutputPath)
$item = Get-Item $OutputPath
Write-Host "Captured PID=$ProcessId HWND=$hwnd -> $OutputPath ($($item.Length) bytes)"
