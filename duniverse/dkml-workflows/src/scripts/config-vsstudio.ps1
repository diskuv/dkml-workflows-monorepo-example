# Diagnose Visual Studio environment variables (Windows)
# This wastes time and has lots of rows! Only run if "VERBOSE" GitHub input key.
if ( "${env:VERBOSE}" -eq "true" ) {
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

# Make export expression [SN]NAME=[SV]VALUE[EV]
# where [SN] is start name and [SV] and [EV] are start and end value
if (("${env:GITLAB_CI}" -eq "true") -or ("${env:PC_CI}" -eq "true")) {
    # Executed immediately in POSIX shell, so must be a real POSIX shell variable declaration
    $ExportSN = "export "
    $ExportSV = "'"
    $ExportEV = "'"
    $ExportExt = ".sh"
} else {
    # Goes into $env:GITHUB_ENV, so must be plain NAME=VALUE
    $ExportSN = ""
    $ExportSV = ""
    $ExportEV = ""
    $ExportExt = ".github"
}

# Locate Visual Studio (Windows)
if ("${env:vsstudio_dir}" -eq "" -and (!(Test-Path -Path .ci/sd4/vsenv${ExportExt}))) {
    $env:PSModulePath += "$([System.IO.Path]::PathSeparator).ci\sd4\g\dkml-runtime-distribution\src\windows"
    Import-Module Machine

    $CompatibleVisualStudios = Get-CompatibleVisualStudios -ErrorIfNotFound
    $CompatibleVisualStudios
    $ChosenVisualStudio = ($CompatibleVisualStudios | Select-Object -First 1)
    $VisualStudioProps = Get-VisualStudioProperties -VisualStudioInstallation $ChosenVisualStudio
    $VisualStudioProps

    Write-Output "${ExportSN}VS_DIR=${ExportSV}$($VisualStudioProps.InstallPath)${ExportEV}" > .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_VCVARSVER=${ExportSV}$($VisualStudioProps.VcVarsVer)${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_WINSDKVER=${ExportSV}$($VisualStudioProps.WinSdkVer)${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_MSVSPREFERENCE=${ExportSV}$($VisualStudioProps.MsvsPreference)${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_CMAKEGENERATOR=${ExportSV}$($VisualStudioProps.CMakeGenerator)${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
}

# Link to hardcoded Visual Studio (Windows)
if ("${env:vsstudio_dir}" -ne "") {
    Write-Output "${ExportSN}VS_DIR=${ExportSV}${env:vsstudio_dir}${ExportEV}" > .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_VCVARSVER=${ExportSV}${env:vsstudio_vcvarsver}${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_WINSDKVER=${ExportSV}${env:vsstudio_winsdkver}${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_MSVSPREFERENCE=${ExportSV}${env:vsstudio_msvspreference}${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
    Write-Output "${ExportSN}VS_CMAKEGENERATOR=${ExportSV}${env:vsstudio_cmakegenerator}${ExportEV}" >> .ci/sd4/vsenv${ExportExt}
}
