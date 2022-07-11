function Install-CasaPackageExt {
    Param(
        $PackageName
    )
    Invoke-Expression "choco.exe install $PackageName --force -y"
}