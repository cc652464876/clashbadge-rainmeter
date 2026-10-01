using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

// Uses Clash Verge's existing registered mode actions. It never PATCHes Mihomo.
// global-hotkey 0.8.0: id = (keyboard_types::Modifiers bits << 16) | Code ordinal.
// Existing ALT+1 => 65542, ALT+2 => 65543. WM_HOTKEY is delivered to that app only.
internal static class ClashBadgeControl
{
    private delegate bool EnumCallback(IntPtr hwnd, IntPtr data);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumCallback callback, IntPtr data);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern int GetClassName(IntPtr hwnd, StringBuilder value, int count);
    [DllImport("user32.dll", SetLastError = true)] private static extern IntPtr SendMessageTimeout(IntPtr hwnd, uint message, UIntPtr wParam, IntPtr lParam, uint flags, uint timeout, out UIntPtr result);
    private static readonly string Root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "io.github.clash-verge-rev.clash-verge-rev");

    private static string ReadMode()
    {
        var request = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:9097/configs");
        request.Proxy = null;
        request.Timeout = 700;
        request.ReadWriteTimeout = 700;
        request.Headers["Authorization"] = "Bearer change-me";
        using (var response = request.GetResponse())
        using (var reader = new StreamReader(response.GetResponseStream()))
        {
            var match = Regex.Match(reader.ReadToEnd(), "\"mode\"\\s*:\\s*\"(global|direct|rule)\"", RegexOptions.IgnoreCase);
            return match.Success ? match.Groups[1].Value.ToLowerInvariant() : "unknown";
        }
    }

    private static bool SavedModeMatches(string mode)
    {
        var config = File.ReadAllText(Path.Combine(Root, "config.yaml"));
        var match = Regex.Match(config, "^mode:\\s*['\"]?(global|direct|rule)['\"]?\\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase);
        return match.Success && match.Groups[1].Value.Equals(mode, StringComparison.OrdinalIgnoreCase);
    }

    private static int Main(string[] args)
    {
        try
        {
            if (args.Length != 1 || (args[0] != "global" && args[0] != "direct"))
                throw new InvalidOperationException("Invalid mode.");
            string mode = args[0];
            string config = File.ReadAllText(Path.Combine(Root, "verge.yaml"));
            string shortcut = mode == "global" ? "ALT+1" : "ALT+2";
            string pattern = "^\\s*-\\s*['\"]?clash_mode_" + mode + "," + Regex.Escape(shortcut) + "['\"]?\\s*$";
            if (!Regex.IsMatch(config, pattern, RegexOptions.Multiline | RegexOptions.IgnoreCase) ||
                !Regex.IsMatch(config, "^enable_global_hotkey:\\s*true\\s*$", RegexOptions.Multiline))
                throw new InvalidOperationException("Clash mode shortcuts have changed or are disabled.");

            var processes = Process.GetProcessesByName("clash-verge");
            IntPtr target = IntPtr.Zero;
            int count = 0;
            EnumCallback callback = delegate(IntPtr hwnd, IntPtr data)
            {
                uint pid;
                GetWindowThreadProcessId(hwnd, out pid);
                foreach (var process in processes)
                {
                    if (process.Id != pid) continue;
                    var name = new StringBuilder(128);
                    GetClassName(hwnd, name, name.Capacity);
                    if (name.ToString() == "global_hotkey_app") { target = hwnd; count++; }
                }
                return true;
            };
            EnumWindows(callback, IntPtr.Zero);
            foreach (var process in processes) process.Dispose();
            if (count != 1) throw new InvalidOperationException("Clash Verge mode action is unavailable.");

            uint id = mode == "global" ? 65542U : 65543U;
            int key = mode == "global" ? 0x31 : 0x32;
            UIntPtr result;
            if (SendMessageTimeout(target, 0x0312, new UIntPtr(id), new IntPtr((key << 16) | 1), 2, 1000, out result) == IntPtr.Zero)
                throw new InvalidOperationException("Clash Verge did not accept the mode action.");

            var timer = Stopwatch.StartNew();
            while (timer.ElapsedMilliseconds < 3500)
            {
                try
                {
                    if (ReadMode() == mode && SavedModeMatches(mode))
                    {
                        Thread.Sleep(100);
                        Console.WriteLine("OK|" + mode);
                        return 0;
                    }
                }
                catch (IOException) { }
                catch (WebException) { }
                Thread.Sleep(60);
            }
            throw new InvalidOperationException("Clash mode did not synchronize; no fallback PATCH was sent.");
        }
        catch (Exception error)
        {
            Console.WriteLine("ERROR|" + error.Message);
            return 1;
        }
    }
}
