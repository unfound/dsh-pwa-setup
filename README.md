# DeepSeek Harness — One-Click Launcher + PWA Install Guide

English | [中文](README.zh.md)

> **Platform support**: this solution has only been verified on **Windows** so far (Edge/Chrome desktop PWA + wscript wrapper + PowerShell scripts).

> **Want it done for you?** Send the text below to your AI assistant (e.g. a DeepSeek Harness agent) and it will fetch the full docs from this repository and walk you through the install:
>
> ```text
> Please visit https://github.com/unfound/dsh-pwa-setup and read the full installation
> documentation (README.md), then help me set up one-click launching for DeepSeek Harness:
> 1. First confirm Node.js is installed (node -v and npm -v print versions); if not, guide me through installing the LTS version.
> 2. Start the service with npx -y @deepseek-ai/dsh web (first run downloads the package); confirm http://127.0.0.1:3080/ opens.
> 3. Guide me through installing the page as an Edge (or Chrome) PWA app to get a desktop shortcut.
> 4. Change the desktop shortcut target to wscript.exe "<local kit folder path>\launch-dsh.vbs", keeping the original icon.
> 5. Verify by double-clicking: when the service is not running it should start automatically, wait until HTTP is ready, then open the UI without flashing a black box; also tell me how to stop the service (Ctrl+C or close the console window).
> Note: this solution has only been verified on Windows so far.
> ```

This kit contains five files:

| File | Purpose |
|---|---|
| `README.md` | This document (English, default) |
| `README.zh.md` | Chinese version of this document |
| `launch-dsh.ps1` | One-click launcher (generic: `npx @deepseek-ai/dsh web`) |
| `launch-dsh.vbs` | No-flash wrapper for double-click (auto-locates the ps1 next to it) |
| `DeepSeek Harness.ico` | Backed-up Edge PWA app icon (use it when changing the shortcut icon) |

---

## Why this approach? (instead of an Electron desktop app)

Many tools "app-ify" their web UI by wrapping it in **Electron** (bundling a full Chromium + Node.js runtime). For a tool like DeepSeek Harness — which is **already a local service + browser UI** — Electron is overkill:

| Aspect | Electron wrapper | This approach (PWA + launcher) |
|---|---|---|
| **Extra memory** | Each app keeps a full Chromium instance resident, **hundreds of MB** even when idle | Reuses the browser **you already have open**; extra memory is **near zero** |
| **Disk footprint** | Hundreds of MB per app (bundled runtime) | Two scripts + one icon, **KB scale** |
| **Install burden** | Download an installer; reinstall to upgrade | One click "Install as an app" in the browser; upgrades come with the browser |
| **Background behavior** | App process stays resident; closing the window may leave it running | Closing the window closes the UI; the service process stays under your control (Ctrl+C / close the window) |
| **Fits your environment** | Ships an isolated runtime, disconnected from the system | Uses the system browser — same look, fonts, proxy, and certificates as everyday browsing |

**The core idea**: DeepSeek Harness's service already runs locally (`http://127.0.0.1:3080`); the browser is just its "display". Instead of wrapping it in another heavyweight runtime, let the **browser you already use** be that display — double-click the icon to bring up the local service and open the PWA window. It feels like a native app, but uses far fewer resources.

---

## 0. Prerequisite: Install Node.js (required)

`npx` ships with Node.js. **Without Node.js the launcher cannot run.**

1. Go to <https://nodejs.org/> and install the **LTS version** (e.g. v22 LTS).
2. After install, **reopen** your terminal / File Explorer (so PATH updates) and verify:

   ```cmd
   node -v
   npm -v
   ```

   Both commands should print a version number.

---

## 1. Two ways to start the service

### Option A: Manual from the command line (quick test)

```cmd
npx -y @deepseek-ai/dsh web
```

- First run downloads the `@deepseek-ai/dsh` package from npm (needs network, ~tens of MB); later runs use the cache and start fast.
- The terminal prints the address (default `http://127.0.0.1:3080`).
- Stop it with `Ctrl+C` in that terminal.

### Option B: One-click via the desktop icon (recommended)

See section 3: point the desktop shortcut at `launch-dsh.vbs`. After that, double-clicking the icon starts the service automatically and opens the UI.

---

## 2. Install the web UI as a browser app (PWA)

Installing creates an "app icon" on the desktop / Start menu; clicking it opens the UI like a standalone desktop program.

### Edge (recommended)

1. Start the service (section 1) and open `http://127.0.0.1:3080/` in Edge.
2. Click **⋯ (Settings and more)** in the top-right → **Apps** → **Install this site as an app**.
3. Click **Install**. The app window opens automatically and a **desktop shortcut is created automatically**.

### Chrome

1. Open `http://127.0.0.1:3080/`.
2. If there is an install icon (monitor with a `+`) in the address bar, click it; otherwise go to **⋯** menu → **Save and share** → **Create shortcut…**.
3. Check **Open as window** and click **Create**. A desktop shortcut is created as well.

> Note: this shortcut **only opens the page** — it does not start the service. To make it "double-click and go", continue to section 3.

---

## 3. Turn the desktop shortcut into a one-click launcher

Principle: change the shortcut target from "open the URL" to "run `launch-dsh.vbs`". On double-click the script: probes the service → starts it in a visible console window if it is not running → waits until HTTP is ready → opens the UI.

### Steps

1. Put this folder in a fixed location (e.g. `C:\Users\<your username>\dsh-pwa-setup\`); **don't move it afterwards**.
2. Right-click the shortcut created above (e.g. 「DeepSeek Harness」) → **Properties** → **Shortcut** tab.
3. In **Target**, enter (keep the quotes; adjust the path to your actual location):

   ```cmd
   wscript.exe "C:\Users\<your username>\dsh-pwa-setup\launch-dsh.vbs"
   ```

4. (Optional) **Change Icon**: click 「Change Icon」 → Browse → pick `DeepSeek Harness.ico` from this kit (backed up from the Edge app), or any icon you like.
5. Click **OK**. Double-click the icon to launch everything at once.

### Stopping the service

In the 「DeepSeek Harness 服务」 console window that the launcher opens, press `Ctrl+C`, or simply close that window.

---

## 4. How the scripts work

### launch-dsh.ps1 (core logic)

- Readiness check: polls `http://127.0.0.1:3080/` over HTTP and **only opens the browser after receiving a 200 response**, avoiding "can't connect" errors.
- Start command: `npx -y @deepseek-ai/dsh web` (working directory = the current user's home).
- Waits up to 90 seconds (first npx download is slow); shows a message box on timeout.
- Edge discovery: reads the registry (`App Paths\msedge.exe`) first, then common install paths, so a custom Edge install location is still found. Falls back to the default browser if Edge cannot be located or no PWA is installed.
- UI opening: prefers the Edge PWA app window if a local PWA install is detected, otherwise the default browser.

### launch-dsh.vbs (no-flash wrapper)

- Uses `wscript.exe` (no console window) to start PowerShell hidden, so double-clicking never flashes a black box.
- Auto-locates `launch-dsh.ps1` in **its own folder**, so both files must stay in the same directory.

---

## 5. Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| Nothing happens on double-click | Node.js not installed (section 0), or the shortcut path is malformed |
| "Service failed to start" message | Check the error in the 「DeepSeek Harness 服务」 window; first npx download is slow, wait and retry |
| `npx is not recognized` | Node.js not installed or PATH not refreshed; reinstall and reopen the terminal |
| Service is running but the icon won't open | Port in use? Check with `netstat -ano \| findstr :3080` |
| Icon stops working after reinstalling the app in Edge | Edge regenerated the shortcut; point the target back to `wscript.exe "…\launch-dsh.vbs"` |

---

## 6. Restore the default behavior

To go back to "open the window only, no service start": restore the shortcut target to the original Edge app URL (visible in Properties), or delete the shortcut and re-pin the app from Edge's app page.
