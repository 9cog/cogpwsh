$ErrorActionPreference = 'Stop'
try {
    Import-Module ./OpenCog.psd1 -Force
    Write-Host "Module imported successfully"
    $count = (Get-Command -Module OpenCog | Measure-Object).Count
    Write-Host "Exported functions: $count"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "At line: $($_.InvocationInfo.ScriptLineNumber)"
    $_.ScriptStackTrace
}
