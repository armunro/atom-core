function Install-AtomPackageExt {
    Param(
        $PackageName
    )
    Invoke-Expression "choco.exe install $PackageName --force -y"
}