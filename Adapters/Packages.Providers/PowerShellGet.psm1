function Install-CasaPackageExt {
    Param(
        $PackageName
    )
    Install-Module $PackageName -Force -Scope CurrentUser
}