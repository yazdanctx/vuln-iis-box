# ==============================================
# IIS LAB SETUP
# Run as Administrator
# ==============================================

Import-Module WebAdministration

$basePath = "C:\inetpub\wwwroot\main"
$siteName = "Default Web Site"
$appName = "main"

Write-Host "[+] Creating directory..." -ForegroundColor Green
New-Item -Path $basePath -ItemType Directory -Force | Out-Null

Write-Host "[+] Configuring IIS Application..." -ForegroundColor Green
if (Get-WebApplication -Site $siteName -Name $appName -ErrorAction SilentlyContinue) {
    Remove-WebApplication -Site $siteName -Name $appName
}
New-WebApplication -Site $siteName -Name $appName -PhysicalPath $basePath -ApplicationPool "DefaultAppPool" -Force

# web.config
Write-Host "[+] Dropping web.config..." -ForegroundColor Green
$webConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.web>
    <machineKey
      validationKey="CB2721ABDAF8E9DC516D621D8B8BF13A2C9E868FEA8B4F7D8C8F8F8F8F8F8F8F"
      decryptionKey="ABCD1234567890ABCD1234567890ABCD"
      validation="SHA1"
      decryption="AES" />
    <pages enableViewState="true" enableViewStateMac="true" viewStateEncryptionMode="Never" />
    <compilation debug="true" targetFramework="4.8" />
    <customErrors mode="Off" />
  </system.web>
  <system.webServer>
    <defaultDocument>
      <files>
        <add value="home.aspx" />
      </files>
    </defaultDocument>
  </system.webServer>
</configuration>
'@
Set-Content -Path "$basePath\web.config" -Value $webConfig -Force

# home.aspx
Write-Host "[+] Dropping home.aspx..." -ForegroundColor Green
$homeAspx = @'
<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head runat="server">
    <title>/root</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{
            background:#000;
            color:#fff;
            font-family:'Courier New',monospace;
            height:100vh;
            display:flex;
            justify-content:center;
            align-items:center
        }
        .term{
            border:1px solid #333;
            padding:2rem;
            width:90%;
            max-width:520px
        }
        .prompt{color:#0f0}
        .cursor{animation:blink 1s infinite}
        @keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
        h1{font-size:1.2rem;font-weight:400;margin-bottom:1rem}
        h1::before{content:'> ';color:#0f0}
        .info{color:#888;font-size:.75rem;margin-bottom:2rem}
        .btn{
            background:#111;
            color:#0f0;
            border:1px solid #333;
            padding:10px 0;
            width:100%;
            cursor:pointer;
            font-family:'Courier New',monospace;
            font-size:.8rem;
            text-transform:uppercase;
            letter-spacing:2px;
            transition:.2s
        }
        .btn:hover{background:#0f0;color:#000;border-color:#0f0}
        .out{
            margin-top:1.5rem;
            padding:1rem;
            background:#0a0a0a;
            border:1px solid #1a1a1a;
            font-size:.75rem;
            color:#0f0
        }
        .out::before{content:'$ ';color:#888}
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="term">
            <h1>session.sys</h1>
            <div class="info">[ INTERNAL DOCUMENT PORTAL v2.4 ]</div>
            <asp:Button ID="Button1" runat="server" Text="[ REFRESH_SESSION ]" OnClick="Button1_Click" CssClass="btn" />
            <div class="out"><asp:Label ID="Label1" runat="server" Text="session_active..."></asp:Label></div>
        </div>
    </form>
</body>
</html>
<script runat="server">
    protected void Button1_Click(object sender, EventArgs e)
    {
        Label1.Text = "session_refreshed @ " + DateTime.Now.ToString("HH:mm:ss");
    }
</script>
'@
Set-Content -Path "$basePath\home.aspx" -Value $homeAspx -Force

# download.aspx
Write-Host "[+] Dropping download.aspx..." -ForegroundColor Green
$downloadAspx = @'
<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<!DOCTYPE html>
<html>
<head runat="server">
    <title>/dl</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{
            background:#000;
            color:#fff;
            font-family:'Courier New',monospace;
            height:100vh;
            display:flex;
            justify-content:center;
            align-items:center
        }
        .term{
            border:1px solid #333;
            padding:2rem;
            width:90%;
            max-width:520px
        }
        h1{font-size:1.2rem;font-weight:400;margin-bottom:1rem}
        h1::before{content:'> ';color:#0f0}
        .info{
            background:#0a0a0a;
            padding:1rem;
            border:1px solid #1a1a1a;
            margin-bottom:1rem;
            font-size:.75rem;
            color:#888
        }
        .cmd{color:#0f0}
        .out{
            padding:1rem;
            background:#0a0a0a;
            border:1px solid #1a1a1a;
            min-height:40px;
            font-size:.75rem;
            color:#0f0;
            white-space:pre-wrap;
            word-break:break-word
        }
        .out::before{content:'$ ';color:#888}
    </style>
</head>
<body>
    <div class="term">
        <h1>download.sys</h1>
        <div class="info">
            <span class="cmd">$ ./download --file=&lt;path&gt;</span>
        </div>
        <div class="out">
<% 
    string fileParam = Request.QueryString["file"];
    if (!string.IsNullOrEmpty(fileParam))
    {
        try
        {
            string physicalPath = Server.MapPath(fileParam);
            if (File.Exists(physicalPath))
            {
                Response.ContentType = "application/octet-stream";
                Response.AddHeader("Content-Disposition", "attachment; filename=\"" + Path.GetFileName(physicalPath) + "\"");
                Response.WriteFile(physicalPath);
            }
            else
            {
                Response.Write("[!] file_not_found: " + fileParam);
            }
        }
        catch (Exception ex)
        {
            Response.Write("[!] error: " + ex.Message);
        }
    }
    else
    {
        Response.Write("[*] awaiting input...");
    }
%>
        </div>
    </div>
</body>
</html>
'@
Set-Content -Path "$basePath\download.aspx" -Value $downloadAspx -Force

# about.aspx
Write-Host "[+] Dropping about.aspx..." -ForegroundColor Green
$aboutAspx = @'
<%@ Page Language="C#" %>
<!DOCTYPE html>
<html>
<head runat="server">
    <title>/info</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{
            background:#000;
            color:#fff;
            font-family:'Courier New',monospace;
            height:100vh;
            display:flex;
            justify-content:center;
            align-items:center
        }
        .term{
            border:1px solid #333;
            padding:2rem;
            width:90%;
            max-width:460px
        }
        h1{font-size:1.2rem;font-weight:400;margin-bottom:1rem}
        h1::before{content:'> ';color:#0f0}
        .line{font-size:.75rem;color:#888;margin-bottom:.5rem}
        .line .key{color:#0f0}
        .badge{
            display:inline-block;
            border:1px solid #0f0;
            color:#0f0;
            padding:4px 12px;
            font-size:.7rem;
            margin-top:1rem;
            text-transform:uppercase;
            letter-spacing:1px
        }
    </style>
</head>
<body>
    <div class="term">
        <h1>system.info</h1>
        <div class="line"><span class="key">name:</span> internal_document_portal</div>
        <div class="line"><span class="key">version:</span> 2.4</div>
        <div class="line"><span class="key">status:</span> operational</div>
        <div class="line"><span class="key">access:</span> authorized_personnel_only</div>
        <div class="badge">[ CLASSIFIED ]</div>
    </div>
</body>
</html>
'@
Set-Content -Path "$basePath\about.aspx" -Value $aboutAspx -Force

# Permissions
Write-Host "[+] Setting permissions..." -ForegroundColor Green
$acl = Get-Acl $basePath
$permission = "IIS AppPool\DefaultAppPool","Read,ReadAndExecute,ListDirectory","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl $basePath $acl

# Recycle
Write-Host "[+] Restarting IIS..." -ForegroundColor Green
iisreset /noforce | Out-Null

Write-Host "`n[+] LAB DEPLOYED" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor DarkGray
Write-Host "http://localhost/main/         -> /root (ViewState RCE)" -ForegroundColor White
Write-Host "http://localhost/main/download.aspx?file= -> /dl (LFI)" -ForegroundColor White
Write-Host "http://localhost/main/about.aspx -> /info" -ForegroundColor White
Write-Host "==============================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "LFI: http://localhost/main/download.aspx?file=../../web.config" -ForegroundColor DarkGray

