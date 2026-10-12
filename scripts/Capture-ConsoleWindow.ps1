# Capture the current console window to a PNG using Win32 PrintWindow/BitBlt.
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Add-Type -AssemblyName System.Drawing | Out-Null
if (-not ("ConsoleCapture" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Drawing.Imaging;

public static class ConsoleCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, int nFlags);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    public static void Save(string path) {
        IntPtr hwnd = GetConsoleWindow();
        if (hwnd == IntPtr.Zero) throw new InvalidOperationException("No console window.");
        SetForegroundWindow(hwnd);
        System.Threading.Thread.Sleep(250);
        RECT r;
        GetWindowRect(hwnd, out r);
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
            System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(path));
            bmp.Save(path, ImageFormat.Png);
        }
    }
}
"@
}

$dir = Split-Path -Parent $OutputPath
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
[ConsoleCapture]::Save($OutputPath)
Write-Host "Saved console capture: $OutputPath"
