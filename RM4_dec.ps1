<#
.SYNOPSIS
    Automatically encrypts or decrypts multiple folders (recursively) using AES-256.
.DESCRIPTION
    AES in CBC mode with PKCS7 padding.
    Each file is overwritten in place with encrypted or decrypted data.
    This version embeds folder paths and password for automation.
#>

# --- Configuration ---
$EmbeddedPassword = "Test"
$EmbeddedFolders = @(
    "C:\Users\auditor-1\Documents\AllData",
    "D:\ConfData"
)
$Mode = "Decrypt"   # Change to "Decrypt" to decrypt automatically instead

# --- AES Key Generation ---
function Get-AESKey {
    param ([string]$Password)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    return $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password))
}

# --- Core Functions ---
function Encrypt-FileInPlace {
    param ([string]$FilePath, [byte[]]$Key)
    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Key = $Key
    $AES.GenerateIV()
    $Encryptor = $AES.CreateEncryptor()
    $PlainBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $CipherBytes = $Encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)
    [System.IO.File]::WriteAllBytes($FilePath, $AES.IV + $CipherBytes)
}

function Decrypt-FileInPlace {
    param ([string]$FilePath, [byte[]]$Key)
    $AllBytes = [System.IO.File]::ReadAllBytes($FilePath)
    if ($AllBytes.Length -lt 17) {
        Write-Host "[!] Skipping invalid or small file: $FilePath"
        return
    }
    $IV = $AllBytes[0..15]
    $CipherBytes = $AllBytes[16..($AllBytes.Length - 1)]
    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Key = $Key
    $AES.IV = $IV
    $Decryptor = $AES.CreateDecryptor()
    try {
        $PlainBytes = $Decryptor.TransformFinalBlock($CipherBytes, 0, $CipherBytes.Length)
        [System.IO.File]::WriteAllBytes($FilePath, $PlainBytes)
    } catch {
        Write-Host "[!] Failed to decrypt (wrong password or corrupted): $FilePath"
    }
}

function Encrypt-Folder {
    param ([string]$FolderPath, [byte[]]$Key)
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[!] Folder not found: $FolderPath"
        return
    }
    $Files = Get-ChildItem -Path $FolderPath -File -Recurse
    foreach ($File in $Files) {
        try {
            Encrypt-FileInPlace -FilePath $File.FullName -Key $Key
            Write-Host "[+] Encrypted: $($File.FullName)"
        } catch {
            Write-Host "[!] Failed to encrypt: $($File.FullName)"
        }
    }
    Write-Host "[OK] Folder encryption complete: $FolderPath`n"
}

function Decrypt-Folder {
    param ([string]$FolderPath, [byte[]]$Key)
    if (-not (Test-Path $FolderPath)) {
        Write-Host "[!] Folder not found: $FolderPath"
        return
    }
    $Files = Get-ChildItem -Path $FolderPath -File -Recurse
    foreach ($File in $Files) {
        try {
            Decrypt-FileInPlace -FilePath $File.FullName -Key $Key
            Write-Host "[+] Decrypted: $($File.FullName)"
        } catch {
            Write-Host "[!] Failed to decrypt: $($File.FullName)"
        }
    }
    Write-Host "[OK] Folder decryption complete: $FolderPath`n"
}

# --- Main Execution ---
Write-Host "AES-256 Multi-Folder Encryptor/Decryptor (Automated)"
$Key = Get-AESKey -Password $EmbeddedPassword

if ($Mode -ieq "Encrypt") {
    foreach ($folder in $EmbeddedFolders) {
        Encrypt-Folder -FolderPath $folder -Key $Key
    }
}
elseif ($Mode -ieq "Decrypt") {
    foreach ($folder in $EmbeddedFolders) {
        Decrypt-Folder -FolderPath $folder -Key $Key
    }
}
else {
    Write-Host "[!] Invalid mode. Please set `$Mode to 'Encrypt' or 'Decrypt'."
}
