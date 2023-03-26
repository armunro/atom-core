function Install-AtomPackageExt {
    Param(
        $PackageName
    )
    Invoke-Expression "winget install -e --id $PackageName "
}