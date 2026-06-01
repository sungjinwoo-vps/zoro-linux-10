// ═══════════════════════════════════════════════════════════════
// zoro-fetch — Zoro Linux System Information Tool
// ═══════════════════════════════════════════════════════════════
// A custom neofetch/fastfetch replacement for Zoro Linux 10.
// Displays system information with Zoro-themed ASCII art.
//
// Install: /usr/bin/zoro-fetch
// Build:   go build -o zoro-fetch .
//
// "I will be the world's greatest swordsman."
// ═══════════════════════════════════════════════════════════════
package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

// ── ANSI Colours ─────────────────────────────────────────────
const (
	colorGreen     = "\033[38;2;82;183;136m"   // #52B788 Blade Green
	colorDarkGreen = "\033[38;2;45;106;79m"    // #2D6A4F Forest Green
	colorGold      = "\033[38;2;201;168;76m"   // #C9A84C Katana Gold
	colorSilver    = "\033[38;2;168;181;200m"   // #A8B5C8 Blade Silver
	colorWhite     = "\033[38;2;245;245;240m"  // #F5F5F0 Rice Paper
	colorBold      = "\033[1m"
	colorReset     = "\033[0m"
)

// ── ASCII Art Logo ──────────────────────────────────────────
var logoLines = []string{
	colorGreen + "              ⚔" + colorReset,
	colorGreen + "             /|\\            " + colorReset,
	colorGreen + "            / | \\           " + colorReset,
	colorGreen + "           /  |  \\          " + colorReset,
	colorDarkGreen + "          /   |   \\         " + colorReset,
	colorDarkGreen + "         /    |    \\        " + colorReset,
	colorGold + "        /  " + colorGreen + "⚔" + colorGold + "  |  " + colorGreen + "⚔" + colorGold + "  \\       " + colorReset,
	colorDarkGreen + "       /     |     \\      " + colorReset,
	colorDarkGreen + "      /      |      \\     " + colorReset,
	colorGreen + "     ────────┼────────    " + colorReset,
	colorGold + "          |||||||          " + colorReset,
	colorGold + "          |||||||          " + colorReset,
	colorSilver + "           |||||           " + colorReset,
	colorSilver + "            |||            " + colorReset,
	colorGold + "             ◆             " + colorReset,
	"",
	colorGreen + colorBold + "    Z O R O   L I N U X" + colorReset,
	colorGold + "     Santoryu Edition" + colorReset,
}

// ── System Info Gathering ───────────────────────────────────

func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return "unknown"
	}
	return hostname
}

func getUsername() string {
	user := os.Getenv("USER")
	if user == "" {
		user = os.Getenv("LOGNAME")
	}
	if user == "" {
		user = "unknown"
	}
	return user
}

func getOSInfo() (string, string) {
	osName := "Zoro Linux"
	osVersion := "10 (Santoryu Edition)"

	// Read from os-release
	file, err := os.Open("/etc/os-release")
	if err != nil {
		return osName, osVersion
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "PRETTY_NAME=") {
			val := strings.TrimPrefix(line, "PRETTY_NAME=")
			val = strings.Trim(val, "'\"")
			parts := strings.SplitN(val, " ", 3)
			if len(parts) >= 2 {
				osName = strings.Join(parts[:2], " ")
			}
			if len(parts) >= 3 {
				osVersion = parts[2]
			}
			return osName, osVersion
		}
	}

	return osName, osVersion
}

func getKernel() string {
	data, err := os.ReadFile("/proc/sys/kernel/osrelease")
	if err != nil {
		return "unknown"
	}
	return strings.TrimSpace(string(data))
}

func getUptime() string {
	data, err := os.ReadFile("/proc/uptime")
	if err != nil {
		return "unknown"
	}

	fields := strings.Fields(string(data))
	if len(fields) == 0 {
		return "unknown"
	}

	seconds, err := strconv.ParseFloat(fields[0], 64)
	if err != nil {
		return "unknown"
	}

	days := int(seconds) / 86400
	hours := (int(seconds) % 86400) / 3600
	minutes := (int(seconds) % 3600) / 60

	if days > 0 {
		return fmt.Sprintf("%dd %dh %dm", days, hours, minutes)
	} else if hours > 0 {
		return fmt.Sprintf("%dh %dm", hours, minutes)
	}
	return fmt.Sprintf("%dm", minutes)
}

func getPackageCount() string {
	// Try DNF first
	out, err := exec.Command("rpm", "-qa", "--qf", "x").Output()
	if err == nil {
		count := len(string(out))
		return fmt.Sprintf("%d (rpm)", count)
	}

	// Fallback: count files in rpm database
	entries, err := filepath.Glob("/var/lib/rpm/Packages*")
	if err == nil && len(entries) > 0 {
		out, err := exec.Command("rpm", "-qa").Output()
		if err == nil {
			lines := strings.Split(strings.TrimSpace(string(out)), "\n")
			return fmt.Sprintf("%d (rpm)", len(lines))
		}
	}

	return "unknown"
}

func getShell() string {
	shell := os.Getenv("SHELL")
	if shell == "" {
		return "unknown"
	}
	// Return just the basename
	return filepath.Base(shell)
}

func getResolution() string {
	// Try xrandr
	out, err := exec.Command("xrandr", "--current").Output()
	if err == nil {
		lines := strings.Split(string(out), "\n")
		for _, line := range lines {
			if strings.Contains(line, "*") {
				fields := strings.Fields(line)
				if len(fields) > 0 {
					return fields[0]
				}
			}
		}
	}

	// Try wlr-randr for Wayland
	out, err = exec.Command("wlr-randr").Output()
	if err == nil {
		lines := strings.Split(string(out), "\n")
		for _, line := range lines {
			if strings.Contains(line, "current") {
				fields := strings.Fields(line)
				if len(fields) > 0 {
					return fields[0]
				}
			}
		}
	}

	return ""
}

func getDE() string {
	de := os.Getenv("XDG_CURRENT_DESKTOP")
	if de == "" {
		de = os.Getenv("DESKTOP_SESSION")
	}
	if de == "" {
		de = os.Getenv("XDG_SESSION_DESKTOP")
	}

	// Map to Zoro names
	switch strings.ToLower(de) {
	case "gnome", "zorodeck":
		return "ZoroDeck (GNOME)"
	case "kde", "plasma", "zoroblade":
		return "ZoroBlade (KDE Plasma)"
	case "xfce":
		return "Xfce"
	case "":
		// Check for WM
		wm := os.Getenv("WINDOWMANAGER")
		if wm != "" {
			return filepath.Base(wm)
		}
		return "TTY"
	default:
		return de
	}
}

func getTerminal() string {
	// Try TERM_PROGRAM first
	term := os.Getenv("TERM_PROGRAM")
	if term != "" {
		return term
	}

	// Try to detect from parent process
	ppid := os.Getppid()
	data, err := os.ReadFile(fmt.Sprintf("/proc/%d/comm", ppid))
	if err == nil {
		comm := strings.TrimSpace(string(data))
		if comm != "bash" && comm != "zsh" && comm != "fish" && comm != "sh" {
			return comm
		}
		// Go up one more level
		statusData, err := os.ReadFile(fmt.Sprintf("/proc/%d/status", ppid))
		if err == nil {
			for _, line := range strings.Split(string(statusData), "\n") {
				if strings.HasPrefix(line, "PPid:") {
					fields := strings.Fields(line)
					if len(fields) >= 2 {
						gpid := fields[1]
						gpComm, err := os.ReadFile(fmt.Sprintf("/proc/%s/comm", gpid))
						if err == nil {
							return strings.TrimSpace(string(gpComm))
						}
					}
				}
			}
		}
	}

	// Fallback to TERM
	term = os.Getenv("TERM")
	if term != "" {
		return term
	}

	return "unknown"
}

func getCPU() string {
	file, err := os.Open("/proc/cpuinfo")
	if err != nil {
		return "unknown"
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "model name") {
			parts := strings.SplitN(line, ":", 2)
			if len(parts) == 2 {
				cpu := strings.TrimSpace(parts[1])
				// Shorten common prefixes
				cpu = strings.ReplaceAll(cpu, "(R)", "")
				cpu = strings.ReplaceAll(cpu, "(TM)", "")
				cpu = strings.ReplaceAll(cpu, "CPU ", "")
				cpu = strings.TrimSpace(cpu)

				// Add core count
				cores := runtime.NumCPU()
				return fmt.Sprintf("%s (%d cores)", cpu, cores)
			}
		}
	}

	return fmt.Sprintf("%s (%d cores)", runtime.GOARCH, runtime.NumCPU())
}

func getGPU() string {
	// Try lspci
	out, err := exec.Command("lspci").Output()
	if err == nil {
		lines := strings.Split(string(out), "\n")
		for _, line := range lines {
			lower := strings.ToLower(line)
			if strings.Contains(lower, "vga") || strings.Contains(lower, "3d") || strings.Contains(lower, "display") {
				parts := strings.SplitN(line, ": ", 2)
				if len(parts) == 2 {
					gpu := strings.TrimSpace(parts[1])
					// Shorten
					gpu = strings.ReplaceAll(gpu, "Corporation ", "")
					gpu = strings.ReplaceAll(gpu, "Integrated Graphics Controller", "Integrated Graphics")
					return gpu
				}
			}
		}
	}

	return ""
}

func getMemory() string {
	file, err := os.Open("/proc/meminfo")
	if err != nil {
		return "unknown"
	}
	defer file.Close()

	var totalKB, availKB int64
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "MemTotal:") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				totalKB, _ = strconv.ParseInt(fields[1], 10, 64)
			}
		}
		if strings.HasPrefix(line, "MemAvailable:") {
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				availKB, _ = strconv.ParseInt(fields[1], 10, 64)
			}
		}
	}

	usedMB := (totalKB - availKB) / 1024
	totalMB := totalKB / 1024

	if totalMB >= 1024 {
		return fmt.Sprintf("%.1f GiB / %.1f GiB",
			float64(usedMB)/1024.0,
			float64(totalMB)/1024.0)
	}
	return fmt.Sprintf("%d MiB / %d MiB", usedMB, totalMB)
}

func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ""
	}
	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
			if ipNet.IP.To4() != nil {
				return ipNet.IP.String()
			}
		}
	}
	return ""
}

func getDiskUsage() string {
	out, err := exec.Command("df", "-h", "/").Output()
	if err != nil {
		return ""
	}
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(lines) >= 2 {
		fields := strings.Fields(lines[1])
		if len(fields) >= 5 {
			return fmt.Sprintf("%s / %s (%s)", fields[2], fields[1], fields[4])
		}
	}
	return ""
}

// ── Separator Line ──────────────────────────────────────────
func separator(username, hostname string) string {
	totalLen := len(username) + 1 + len(hostname) // user@host
	return strings.Repeat("─", totalLen)
}

// ── Main Output ─────────────────────────────────────────────
func main() {
	username := getUsername()
	hostname := getHostname()
	osName, osVersion := getOSInfo()
	kernel := getKernel()
	uptime := getUptime()
	packages := getPackageCount()
	shell := getShell()
	resolution := getResolution()
	de := getDE()
	terminal := getTerminal()
	cpu := getCPU()
	gpu := getGPU()
	memory := getMemory()
	localIP := getLocalIP()
	disk := getDiskUsage()


	// Build info lines
	var infoLines []string

	// Header
	infoLines = append(infoLines,
		fmt.Sprintf("%s%s%s%s@%s%s%s",
			colorGreen, colorBold, username, colorGold, colorGreen, hostname, colorReset))
	infoLines = append(infoLines,
		colorSilver+separator(username, hostname)+colorReset)

	// Info fields
	addField := func(label, value string) {
		if value != "" {
			infoLines = append(infoLines,
				fmt.Sprintf("%s%s%-12s%s%s%s",
					colorGold, colorBold, label, colorReset, colorWhite, value))
		}
	}

	addField("OS", fmt.Sprintf("%s %s", osName, osVersion))
	addField("Kernel", kernel)
	addField("Uptime", uptime)
	addField("Packages", packages)
	addField("Shell", shell)
	if resolution != "" {
		addField("Resolution", resolution)
	}
	addField("DE/WM", de)
	addField("Terminal", terminal)
	addField("CPU", cpu)
	if gpu != "" {
		addField("GPU", gpu)
	}
	addField("RAM", memory)
	if disk != "" {
		addField("Disk (/)", disk)
	}
	if localIP != "" {
		addField("Local IP", localIP)
	}

	// Colour palette display
	infoLines = append(infoLines, "")
	infoLines = append(infoLines,
		"\033[48;2;45;106;79m   \033[0m"+
			"\033[48;2;26;58;42m   \033[0m"+
			"\033[48;2;82;183;136m   \033[0m"+
			"\033[48;2;201;168;76m   \033[0m"+
			"\033[48;2;139;105;20m   \033[0m"+
			"\033[48;2;168;181;200m   \033[0m"+
			"\033[48;2;240;234;214m   \033[0m"+
			"\033[48;2;13;17;23m   \033[0m")

	// Output: logo on left, info on right
	maxLines := len(logoLines)
	if len(infoLines) > maxLines {
		maxLines = len(infoLines)
	}

	fmt.Println()
	for i := 0; i < maxLines; i++ {
		logoLine := ""
		if i < len(logoLines) {
			logoLine = logoLines[i]
		}

		infoLine := ""
		if i < len(infoLines) {
			infoLine = infoLines[i]
		}

		// Pad logo column (30 visible chars)
		fmt.Printf("  %-30s  %s\n", logoLine, infoLine)
	}
	fmt.Println()

	// Zoro quote
	quotes := []string{
		"\"Nothing happened.\"",
		"\"I will be the world's greatest swordsman.\"",
		"\"I don't care what the society says. I've regretted doing things my way.\"",
		"\"If I die here, then I'm a man that could only make it this far.\"",
		"\"Bring on the hardship. It's preferred in a path of carnage.\"",
	}

	// Pick quote based on day of year (deterministic per day)
	dayOfYear := time.Now().YearDay()
	quote := quotes[dayOfYear%len(quotes)]
	fmt.Printf("  %s%s  — Roronoa Zoro%s\n\n", colorSilver, quote, colorReset)
}
