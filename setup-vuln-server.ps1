# ==============================================
# H4CK3R STYLE IIS LAB SETUP
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

# ==============================================
# PUBLIC FILES (accessible via direct URL)
# ==============================================

# 1. robots.txt
Write-Host "[+] Dropping robots.txt..." -ForegroundColor Green
$robotsTxt = @'
User-agent: *
Disallow: /admin/
Disallow: /backup/
Disallow: /config/

# FLAG{robots_reveal_the_paths_8472}
# Internal paths - do not index
# dev backup: /backup/db_export_2024.sql
'@
Set-Content -Path "$basePath\robots.txt" -Value $robotsTxt -Force

# 2. README.md
Write-Host "[+] Dropping README.md..." -ForegroundColor Green
$readmeMd = @'
# Internal Document Portal v2.4

## Access Credentials
- Dev environment: http://localhost/main/
- Staging: http://staging.internal.corp/main/

## Changelog
- v2.4: Fixed session handling
- v2.3: Added download portal
- v2.2: Patched critical auth bypass (CVE-2024-1234)

## Notes
FLAG{docs_left_in_the_open_5541}
DO NOT COMMIT CREDENTIALS TO REPO
'@
Set-Content -Path "$basePath\README.md" -Value $readmeMd -Force

# ==============================================
# HIDDEN FILES (only via LFI on download.aspx)
# ==============================================

# 3. Hidden config backup
Write-Host "[+] Dropping web.config.bak..." -ForegroundColor Green
$webConfigBak = @'
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
  <!-- FLAG{bak_files_are_gold_7331} -->
  <!-- Dev note: keep this backup in case web.config breaks -->
</configuration>
'@
Set-Content -Path "$basePath\web.config.bak" -Value $webConfigBak -Force

# 4. Hidden credentials file
Write-Host "[+] Dropping .env..." -ForegroundColor Green
$envFile = @'
# Database Configuration
DB_HOST=192.168.1.100
DB_PORT=1433
DB_USER=sa
DB_PASS=S3cur3P@ssw0rd2024!
DB_NAME=internal_docs

# SMTP Configuration
SMTP_HOST=mail.internal.corp
SMTP_PORT=587
SMTP_USER=noreply@internal.corp
SMTP_PASS=M@ilS3rv3r!

# API Keys
API_KEY=sk-9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c
FLAG{dotenv_exposed_9902}

# JWT Secret
JWT_SECRET=Th1sIsASup3rS3cr3tJWTK3y!
'@
Set-Content -Path "$basePath\.env" -Value $envFile -Force

# 5. Hidden backup SQL dump
Write-Host "[+] Dropping db_backup.sql..." -ForegroundColor Green
$sqlDump = @'
-- Database backup: internal_docs
-- Date: 2024-01-15
-- Server: DB-PROD-01

CREATE TABLE users (
    id INT PRIMARY KEY,
    username VARCHAR(50),
    password_hash VARCHAR(255),
    role VARCHAR(20)
);

INSERT INTO users VALUES (1, 'admin', '5f4dcc3b5aa765d61d8327deb882cf99', 'administrator');
INSERT INTO users VALUES (2, 'jsmith', '7c6a180b36896a0a8c02787eeafb0e4c', 'editor');
INSERT INTO users VALUES (3, 'mjones', '6cb75f652a9b52798eb6cf2201057c73', 'viewer');

-- FLAG{sql_dump_leaked_4561}
-- Dev credentials for local testing
-- admin:password123
-- Remember to change before prod deployment!
'@
Set-Content -Path "$basePath\db_backup.sql" -Value $sqlDump -Force

# ==============================================
# CORE APPLICATION FILES
# ==============================================

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
            max-width:480px
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

# ==============================================
# PERMISSIONS & RESTART
# ==============================================

Write-Host "[+] Setting permissions..." -ForegroundColor Green
$acl = Get-Acl $basePath
$permission = "IIS AppPool\DefaultAppPool","Read,ReadAndExecute,ListDirectory","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl $basePath $acl

Write-Host "[+] Restarting IIS..." -ForegroundColor Green
iisreset /noforce | Out-Null

Write-Host "`n[+] LAB DEPLOYED" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor DarkGray
Write-Host "TARGET: http://localhost/main/" -ForegroundColor White
Write-Host "==============================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "PUBLIC FILES (direct access):" -ForegroundColor Yellow
Write-Host "  http://localhost/main/robots.txt" -ForegroundColor White
Write-Host "  http://localhost/main/README.md" -ForegroundColor White
Write-Host ""
Write-Host "HIDDEN FILES (LFI via download.aspx):" -ForegroundColor Red
Write-Host "  http://localhost/main/download.aspx?file=web.config.bak" -ForegroundColor White
Write-Host "  http://localhost/main/download.aspx?file=.env" -ForegroundColor White
Write-Host "  http://localhost/main/download.aspx?file=db_backup.sql" -ForegroundColor White
Write-Host ""
Write-Host "FUZZING COMMANDS:" -ForegroundColor Cyan
Write-Host "  shortscan http://localhost/main/" -ForegroundColor White
Write-Host "  ffuf -u http://localhost/main/FUZZ -w wordlist.txt" -ForegroundColor White
Write-Host ""
Write-Host "FLAGS TO FIND:" -ForegroundColor Magenta
Write-Host "  FLAG{robots_reveal_the_paths_8472}" -ForegroundColor White
Write-Host "  FLAG{docs_left_in_the_open_5541}" -ForegroundColor White
Write-Host "  FLAG{bak_files_are_gold_7331}" -ForegroundColor White
Write-Host "  FLAG{dotenv_exposed_9902}" -ForegroundColor White
Write-Host "  FLAG{sql_dump_leaked_4561}" -ForegroundColor White
