$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
# 계약이 바뀌었는데 생성물이 낡았으면 여기서 막는다.
python3 (Join-Path $root 'contract/generate.py') --check
if ($LASTEXITCODE -ne 0) { throw '계약 생성물이 낡았습니다. python3 contract/generate.py 를 돌리세요.' }

$dotnet = $env:DOTNET_ROOT
if ([string]::IsNullOrWhiteSpace($dotnet)) { $dotnet = 'dotnet' } else { $dotnet = Join-Path $dotnet 'dotnet.exe' }
& $dotnet publish (Join-Path $PSScriptRoot 'TtalkkakTuner.Windows.csproj') -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o (Join-Path $root 'windows-dist')
