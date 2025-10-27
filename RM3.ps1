<#
.SYNOPSIS
    Encrypts or decrypts multiple folders (recursively) using AES-256.
.DESCRIPTION
    AES in CBC mode with PKCS7 padding.
    Each file is overwritten in place with encrypted or decrypted data.
#>

function Get-AESKey {
    param (
        [string]$Password
    )
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $key = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password))
    return $key
}

function Encrypt-FileInPlace {
    param (
        [string]$FilePath,
        [byte[]]$Key
    )

    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Key = $Key
    $AES.GenerateIV()
    $Encryptor = $AES.CreateEncryptor()

    $PlainBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $CipherBytes = $Encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)

    # Save IV + Ciphertext back into the same file
    [System.IO.File]::WriteAllBytes($FilePath, $AES.IV + $CipherBytes)
}

function Decrypt-FileInPlace {
    param (
        [string]$FilePath,
        [byte[]]$Key
    )

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
    }
    catch {
        Write-Host "[!] Failed to decrypt (wrong password or corrupted): $FilePath"
    }
}

function Encrypt-Folder {
    param (
        [string]$FolderPath,
        [byte[]]$Key
    )

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
    param (
        [string]$FolderPath,
        [byte[]]$Key
    )

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

# --- User Interface ---
Write-Host "AES-256 Multi-Folder Encryptor/Decryptor (In-Place)"
$choice = Read-Host "Do you want to (E)ncrypt or (D)ecrypt?"
$password = Read-Host "Enter password (same for decryption)"

# --- Accept multiple folder paths ---
$folders = @()
Write-Host "`nEnter folder paths one by one. Press ENTER on an empty line when done.`n"

while ($true) {
    $inputPath = Read-Host "Enter folder path"
    if ([string]::IsNullOrWhiteSpace($inputPath)) { break }
    $folders += $inputPath
}

if ($folders.Count -eq 0) {
    Write-Host "[!] No folders entered. Exiting."
    exit
}

$Key = Get-AESKey -Password $password

if ($choice -eq 'E' -or $choice -eq 'e') {
    foreach ($folder in $folders) {
        Encrypt-Folder -FolderPath $folder -Key $Key
    }
}
elseif ($choice -eq 'D' -or $choice -eq 'd') {
    foreach ($folder in $folders) {
        Decrypt-Folder -FolderPath $folder -Key $Key
    }
}
else {
    Write-Host "Invalid choice."
}
