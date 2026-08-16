# ===== DeepSeek Harness 一键启动器（通用版 v2） =====
# 用 npx @deepseek-ai/dsh web 启动服务，不依赖本地仓库路径。
# 前置要求：安装 Node.js（含 npx）。首次运行会从 npm 下载 dsh 包。
# 流程：探测 HTTP 就绪 → 没就绪则打开可见控制台窗口跑 npx dsh web
#       → 轮询等待 HTTP 200 → 打开界面（优先 Edge PWA 应用窗口，否则默认浏览器）。
# 关闭服务：在「DeepSeek Harness 服务」窗口按 Ctrl+C，或直接关闭该窗口。
# Edge 定位：注册表 App Paths 优先，其次常见安装路径，找不到则退回默认浏览器。

$Port   = 3080
$Url    = "http://127.0.0.1:$Port/"
# npx 在用户主目录下执行（dsh 会把该目录当作默认工作区根）
$WorkDir = $env:USERPROFILE
$EdgeAppId  = "hgiemfgfjhalibdoboikeiepnnjapnpc"
$PwaDataDir = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Web Applications\_crx__$EdgeAppId"

# 就绪判断：HTTP 请求能拿到 200 响应才算真正就绪（仅端口监听不代表后端已可响应）
function Test-HttpReady {
  try {
    $req = [System.Net.HttpWebRequest]::Create($Url)
    $req.Timeout = 1500
    $req.AllowAutoRedirect = $false
    $req.Proxy = $null
    $resp = $req.GetResponse()
    $code = [int]$resp.StatusCode
    $resp.Close()
    return ($code -ge 200 -and $code -lt 500)
  } catch { return $false }
}

# 定位 Edge 应用启动器：注册表优先，其次常见路径；找不到返回 $null。
# 返回 msedge_proxy.exe（PWA 窗口启动器）；无 proxy 时退回 msedge.exe。
function Find-EdgeLauncher {
  $candidates = @()
  try {
    $v = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" -ErrorAction Stop).'(default)'
    if ($v) { $candidates += $v }
  } catch {}
  $candidates += @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
  )
  $msedge = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $msedge) { return $null }
  $proxy = Join-Path (Split-Path $msedge) "msedge_proxy.exe"
  if (Test-Path $proxy) { return $proxy }
  return $msedge
}

# 1) 服务没就绪 → 打开可见控制台窗口跑 npx @deepseek-ai/dsh web
if (-not (Test-HttpReady)) {
  Start-Process -FilePath "cmd.exe" `
                -ArgumentList "/k", "title DeepSeek Harness 服务 && npx -y @deepseek-ai/dsh web" `
                -WorkingDirectory $WorkDir | Out-Null
  # 2) 轮询等待 HTTP 就绪（首次下载 npx 包较慢，最长等 90 秒）
  $deadline = (Get-Date).AddSeconds(90)
  while (-not (Test-HttpReady) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 800 }
  # 3) 90 秒还没就绪 → 弹窗提示去看控制台窗口的报错
  if (-not (Test-HttpReady)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
      "服务启动似乎失败了，请检查『DeepSeek Harness 服务』窗口中的报错信息。", "DeepSeek Harness") | Out-Null
    exit 1
  }
  # 4) 已就绪，再等 1 秒缓冲，确保页面资源可访问
  Start-Sleep -Seconds 1
}

# 5) 打开界面：装了 PWA 就开独立应用窗口，没装就默认浏览器
$edge = Find-EdgeLauncher
if ($edge -and (Test-Path $PwaDataDir)) {
  Start-Process -FilePath $edge -ArgumentList "--profile-directory=Default","--app-id=$EdgeAppId","--app-url=$Url","--app-launch-source=4"
} else {
  Start-Process $Url
}
