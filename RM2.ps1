<#
.SYNOPSIS
    Encrypts or decrypts all files in a folder (recursively) using AES-256.
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
        [string]$Password
    )

    $Key = Get-AESKey -Password $Password
    $Files = Get-ChildItem -Path $FolderPath -File -Recurse

    foreach ($File in $Files) {
        try {
            Encrypt-FileInPlace -FilePath $File.FullName -Key $Key
            Write-Host "[+] Encrypted: $($File.FullName)"
        } catch {
            Write-Host "[!] Failed to encrypt: $($File.FullName)"
        }
    }
    Write-Host "`n[+] Folder encryption complete."
}

function Decrypt-Folder {
    param (
        [string]$FolderPath,
        [string]$Password
    )

    $Key = Get-AESKey -Password $Password
    $Files = Get-ChildItem -Path $FolderPath -File -Recurse

    foreach ($File in $Files) {
        try {
            Decrypt-FileInPlace -FilePath $File.FullName -Key $Key
            Write-Host "[+] Decrypted: $($File.FullName)"
        } catch {
            Write-Host "[!] Failed to decrypt: $($File.FullName)"
        }
    }
    Write-Host "`n[+] Folder decryption complete."
}

# --- User Interface ---
Write-Host "AES-256 Folder Encryptor/Decryptor (In-Place)"
$choice = Read-Host "Do you want to (E)ncrypt or (D)ecrypt?"
$folder = Read-Host "Enter full folder path"
$password = Read-Host "Enter password (same for decryption)"

if ($choice -eq 'E') {
    Encrypt-Folder -FolderPath $folder -Password $password
}
elseif ($choice -eq 'D') {
    Decrypt-Folder -FolderPath $folder -Password $password
}
else {
    Write-Host "Invalid choice."
}
