function Get-AtomCommandParams {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Command   
    )
    process {
        $paramRequests = @{}
        $scriptParamsAst = $Command.ScriptBlock.Ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.ParameterAst]
            }, $true)

        $scriptParamsAst | ForEach-Object {
            $mandatory = [Boolean]( $_.Attributes |
                Where-Object { $_.TypeName.Name -eq "Parameter" } |
                ForEach-Object -MemberName NamedArguments |
                Where-Object { $_.ArgumentName -eq 'Mandatory' }).Argument

            $paramkey = $_.Name.ToString().Trim('$')
            $paramRequests[$paramkey] = [PSCustomObject] @{
                Name         = $paramkey;
                DefaultValue = $_.DefaultValue;
                Mandatory    = $mandatory
            }
        }

        return $paramRequests
    }

}

function Invoke-AtomCommand {
    [CmdletBinding()]
    [Alias("amp")]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $Command,
        [Hashtable]
        $Params
    )

    if ($Params) {
        $Params.Keys | Foreach-Object {
            Set-AtomParamValue -AtomKey ($Command | Get-AtomCommandKey -ParamName $_) -Scope Invoke -Value $Params[$_]
            
            Write-Host $Params[$_]
        }
    }

    Write-AtomBanner -Verb Parameters -Type Command -Icon ""
    $commandParams = ($Command | Get-AtomCommandParams)
    

    $invokeParams = @{}
    foreach ($paramName in $commandParams.Keys) {
        $param = $commandParams[$paramName]
        $AtomKey = ($Command | Get-AtomCommandKey -ParamName $paramName)
        $paramValue = ($AtomKey | Get-AtomParamValue)
        

        Write-AtomListItem -Text $($param.Name) -Icon "" -NoNewline


        Write-Host " [Mandatory: $($param.Mandatory)]" -NoNewline -ForegroundColor Blue
        Write-Host " [Default: $($param.DefaultValue)]" -ForegroundColor Cyan -NoNewline

        if ([System.String]::IsNullOrWhiteSpace($paramValue)) {
            Write-Host " MISSING" -ForegroundColor Yellow
        }
        else {
            Write-Host " FOUND {$paramValue}" -ForegroundColor Green
            $invokeParams[$paramName] = ($paramValue | Select-Object -First 1)
        }
    }
    
    
    Write-AtomBanner -Verb Exec -Type $Command.Name -Icon "異"
    & $Command @invokeParams

}