<#
.SYNOPSIS
    Encrypts or decrypts files in-place using AES-256.
.DESCRIPTION
    AES in CBC mode with PKCS7 padding.
    File is overwritten with encrypted or decrypted data.
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
        [string]$Password
    )

    $Key = Get-AESKey -Password $Password
    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Key = $Key
    $AES.GenerateIV()
    $Encryptor = $AES.CreateEncryptor()

    $PlainBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $CipherBytes = $Encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)

    # Save IV + Ciphertext back into the same file
    [System.IO.File]::WriteAllBytes($FilePath, $AES.IV + $CipherBytes)

    Write-Host "[+] File encrypted successfully and overwritten: $FilePath"
}

function Decrypt-FileInPlace {
    param (
        [string]$FilePath,
        [string]$Password
    )

    $Key = Get-AESKey -Password $Password
    $AllBytes = [System.IO.File]::ReadAllBytes($FilePath)

    # Extract IV and ciphertext
    $IV = $AllBytes[0..15]
    $CipherBytes = $AllBytes[16..($AllBytes.Length - 1)]

    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Key = $Key
    $AES.IV = $IV
    $Decryptor = $AES.CreateDecryptor()

    try {
        $PlainBytes = $Decryptor.TransformFinalBlock($CipherBytes, 0, $CipherBytes.Length)
        [System.IO.File]::WriteAllBytes($FilePath, $PlainBytes)
        Write-Host "[+] File decrypted successfully and restored: $FilePath"
    }
    catch {
        Write-Host "[!] Decryption failed — wrong password or corrupted file."
    }
}

# --- User Interface ---
Write-Host "AES-256 File Encryptor/Decryptor (In-Place)"
$choice = Read-Host "Do you want to (E)ncrypt or (D)ecrypt?"
$file = Read-Host "Enter full file path (.txt or .docx)"
$password = Read-Host "Enter password (same for decryption)"

if ($choice -eq 'E') {
    Encrypt-FileInPlace -FilePath $file -Password $password
}
elseif ($choice -eq 'D') {
    Decrypt-FileInPlace -FilePath $file -Password $password
}
else {
    Write-Host "Invalid choice."
}
