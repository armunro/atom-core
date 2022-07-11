function Install-AtomPackageExt {
    Param(
        $PackageName
    )
    Install-Module $PackageName -Force -Scope CurrentUser
}