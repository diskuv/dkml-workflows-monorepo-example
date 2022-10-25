# setup-dkml
#   Short form: sd4
  
[CmdletBinding()]
param (
  # Context variables
  [Parameter()]
  [string]
  $PC_PROJECT_DIR = $PWD,

  # Input variables
  [Parameter()]
  [string]
  $FDOPEN_OPAMEXE_BOOTSTRAP = "false",
  [Parameter()]
  [string]
  $CACHE_PREFIX = "v1",
  [Parameter()]
  [string]
  $OCAML_COMPILER = "",
  [Parameter()]
  [string]
  $DKML_COMPILER = "", # "@repository@" = Opam ; "" = latest from default branch ("main") of git clone
  [Parameter()]
  [string]
  $CONF_DKML_CROSS_TOOLCHAIN = "@repository@", # "@repository@" = Opam ; "" = latest from default branch of git clone
  [Parameter()]
  [string]
  $DISKUV_OPAM_REPOSITORY = "" # DEFAULT_DISKUV_OPAM_REPOSITORY_TAG is used as default for empty strings

  # Conflicts with automatic variable $Verbose
  # [Parameter()]
  # [string]
  # $VERBOSE = "false"
    
  # Environment variables (can be overridden on command line)
  # autogen from global_env_vars.{% for var in global_env_vars %}{{ nl }}    ,[Parameter()] [string] ${{ var.name }} = "{{ var.value }}"{% endfor %}
)

$ErrorActionPreference = "Stop"

# Pushdown context variables
$env:PC_CI = 'true'
$env:PC_PROJECT_DIR = $PC_PROJECT_DIR

# Pushdown input variables
$env:FDOPEN_OPAMEXE_BOOTSTRAP = $FDOPEN_OPAMEXE_BOOTSTRAP
$env:CACHE_PREFIX = $CACHE_PREFIX
$env:OCAML_COMPILER = $OCAML_COMPILER
$env:DKML_COMPILER = $DKML_COMPILER
$env:CONF_DKML_CROSS_TOOLCHAIN = $CONF_DKML_CROSS_TOOLCHAIN
$env:DISKUV_OPAM_REPOSITORY = $DISKUV_OPAM_REPOSITORY

# Set matrix variables
# autogen from pc_matrix. only windows_x86_64{% for outer in pc_matrix %}{%- if outer.dkml_host_abi == "windows_x86_64" -%}{{ nl }}{% for var in outer.vars %}$env:{{ var.name }} = "{{ var.value }}"{{ nl }}{% endfor %}{%- endif %}{% endfor %}

# Set environment variables
# autogen from global_env_vars.{% for var in global_env_vars %}{{ nl }}$env:{{ var.name }} = ${{ var.name }}{% endfor %}

# https://patchwork.kernel.org/project/qemu-devel/patch/20211215073402.144286-17-thuth@redhat.com/
$env:CHERE_INVOKING = "yes" # Preserve the current working directory
$env:MSYSTEM = $env:msys2_system # Start a 64 bit environment if CLANG64, etc.

########################### before_script ###############################

# Troubleshooting
If ( "${env:VERBOSE}" -eq "true" ) { Get-ChildItem 'env:' }

# -----
# MSYS2
# -----
#
# https://www.msys2.org/docs/ci/
# https://patchwork.kernel.org/project/qemu-devel/patch/20211215073402.144286-17-thuth@redhat.com/

if ( Test-Path -Path msys64\usr\bin\pacman.exe ) {
  Write-Host "Re-using MSYS2 from cache."
}
else {
  Write-Host "Download the archive ..."
  If ( !(Test-Path -Path msys64\var\cache ) ) { New-Item msys64\var\cache -ItemType Directory | Out-Null }
  If ( !(Test-Path -Path msys64\var\cache\msys2.exe ) ) { Invoke-WebRequest "https://github.com/msys2/msys2-installer/releases/download/2022-09-04/msys2-base-x86_64-20220904.sfx.exe" -outfile "msys64\var\cache\msys2.exe" }

  Write-Host "Extract the archive ..."
  msys64\var\cache\msys2.exe -y # Extract to .\msys64
  Remove-Item msys64\var\cache\msys2.exe # Delete the archive again
  ((Get-Content -path msys64\etc\post-install\07-pacman-key.post -Raw) -replace '--refresh-keys', '--version') | Set-Content -Path msys64\etc\post-install\07-pacman-key.post
  msys64\usr\bin\bash -lc "sed -i 's/^CheckSpace/#CheckSpace/g' /etc/pacman.conf"

  Write-Host "Run for the first time ..."
  msys64\usr\bin\bash -lc ' '
}
Write-Host "Update MSYS2 ..."
msys64\usr\bin\bash -lc 'pacman --noconfirm -Syuu' # Core update (in case any core packages are outdated)
msys64\usr\bin\bash -lc 'pacman --noconfirm -Syuu' # Normal update
taskkill /F /FI "MODULES eq msys-2.0.dll"

Write-Host "Install matrix, required and CI packages ..."
#   Packages for GitLab CI:
#     dos2unix (used to translate PowerShell written files below in this CI .yml into MSYS2 scripts)
msys64\usr\bin\bash -lc 'set -x; pacman -Sy --noconfirm --needed ${msys2_packages} {% for var in required_msys2_packages %} {{ var }} {%- endfor %} dos2unix'

Write-Host "Uninstall MSYS2 conflicting executables ..."
msys64\usr\bin\bash -lc 'rm -vf /usr/bin/link.exe' # link.exe interferes with MSVC's link.exe

Write-Host "Installing VSSetup for the Get-VSSetupInstance function ..."
Install-Module VSSetup -Scope CurrentUser -Force

Write-Host "Writing scripts ..."

# POSIX and AWK scripts

If ( !(Test-Path -Path.ci\sd4 ) ) { New-Item .ci\sd4 -ItemType Directory | Out-Null }

$Content = @'
{{ pc_common_values_script }}
'@
Set-Content -Path ".ci\sd4\common-values.sh" -Encoding Unicode -Value $Content
msys64\usr\bin\bash -lc 'dos2unix .ci/sd4/common-values.sh'


$Content = @'
{{ pc_checkout_code_script }}
'@
Set-Content -Path ".ci\sd4\run-checkout-code.sh" -Encoding Unicode -Value $Content
msys64\usr\bin\bash -lc 'dos2unix .ci/sd4/run-checkout-code.sh'


$Content = @'
{{ pc_setup_dkml_script }}
'@
Set-Content -Path ".ci\sd4\run-setup-dkml.sh" -Encoding Unicode -Value $Content
msys64\usr\bin\bash -lc 'dos2unix .ci/sd4/run-setup-dkml.sh'

$Content = @'
{{ pc_msvcenv_awk }}
'@
Set-Content -Path ".ci\sd4\msvcenv.awk" -Encoding Unicode -Value $Content
msys64\usr\bin\bash -lc 'dos2unix .ci/sd4/msvcenv.awk'


$Content = @'
{{ pc_msvcpath_awk }}
'@
Set-Content -Path ".ci\sd4\msvcpath.awk" -Encoding Unicode -Value $Content
msys64\usr\bin\bash -lc 'dos2unix .ci/sd4/msvcpath.awk'

# PowerShell (UTF-16) and Batch (ANSI) scripts


$Content = @'
{{ pc_config_vsstudio_ps1 }}
'@
Set-Content -Path ".ci\sd4\config-vsstudio.ps1" -Encoding Unicode -Value $Content


$Content = @'
{{ pc_get_msvcpath_cmd }}

REM * We can't use `bash -lc` directly to query for all MSVC environment variables
REM   because it stomps over the PATH. So we are inside a Batch script to do the query.
msys64\usr\bin\bash -lc "set | grep -v '^PATH=' | awk -f .ci/sd4/msvcenv.awk > .ci/sd4/msvcenv"
'@
Set-Content -Path ".ci\sd4\get-msvcpath-into-msys2.cmd" -Encoding Default -Value $Content

msys64\usr\bin\bash -lc "sh .ci/sd4/run-checkout-code.sh PC_PROJECT_DIR '${env:PC_PROJECT_DIR}'"

# Diagnose Visual Studio environment variables (Windows)
# This wastes time and has lots of rows! Only run if "VERBOSE" GitHub input key.

If ( "${env:VERBOSE}" -eq "true" ) {
  if (Test-Path -Path "C:\Program Files (x86)\Windows Kits\10\include") {
    Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\include"
  }
  if (Test-Path -Path "C:\Program Files (x86)\Windows Kits\10\Extension SDKs\WindowsDesktop") {
    Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\Extension SDKs\WindowsDesktop"
  }

  $env:PSModulePath += "$([System.IO.Path]::PathSeparator).ci\sd4\g\dkml-runtime-distribution\src\windows"
  Import-Module Machine

  $allinstances = Get-VSSetupInstance
  $allinstances | ConvertTo-Json -Depth 5
}
.ci\sd4\config-vsstudio.ps1
msys64\usr\bin\bash -lc "dos2unix .ci/sd4/vsenv.sh"
Get-Content .ci/sd4/vsenv.sh

# Capture Visual Studio compiler environment
msys64\usr\bin\bash -lc ". .ci/sd4/vsenv.sh && cmd /c .ci/sd4/get-msvcpath-into-msys2.cmd"
msys64\usr\bin\bash -lc "cat .ci/sd4/msvcpath | tr -d '\r' | cygpath --path -f - | awk -f .ci/sd4/msvcpath.awk >> .ci/sd4/msvcenv"    
msys64\usr\bin\bash -lc "tail -n100 .ci/sd4/msvcpath .ci/sd4/msvcenv"

msys64\usr\bin\bash -lc "sh .ci/sd4/run-setup-dkml.sh PC_PROJECT_DIR '${env:PC_PROJECT_DIR}'"

########################### script ###############################

Write-Host @"
Finished setup.

To continue your testing, run in PowerShell:
  \$env:CHERE_INVOKING = "yes"
  \$env:MSYSTEM = "$env:msys2_system"
  \$env:dkml_host_abi = "$env:dkml_host_abi"
  \$env:abi_pattern = "$env:abi_pattern"
  \$env:opam_root = "$env:opam_root"
  \$env:exe_ext = "${env:exe_ext}"
  \$env:PC_PROJECT_DIR = $PWD

  msys64\usr\bin\bash -lc 'PATH="\$PWD/.ci/sd4/opamrun:\$PATH"; opamrun install XYZ.opam'

Use can you any opam-like command you want.
"@
