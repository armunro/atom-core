function Get-CasaCommandParams {
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

function Invoke-CasaCommand {
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
            Set-CasaParamValue -CasaKey ($Command | Get-CasaCommandKey -ParamName $_) -Scope Invoke -Value $Params[$_]
            
            Write-Host $Params[$_]
        }
    }

    Write-CasaBanner -Verb Parameters -Type Command -Icon ""
    $commandParams = ($Command | Get-CasaCommandParams)
    

    $invokeParams = @{}
    foreach ($paramName in $commandParams.Keys) {
        $param = $commandParams[$paramName]
        $CasaKey = ($Command | Get-CasaCommandKey -ParamName $paramName)
        $paramValue = ($CasaKey | Get-CasaParamValue)
        

        Write-CasaListItem -Text $($param.Name) -Icon "" -NoNewline


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
    
    
    Write-CasaBanner -Verb Exec -Type $Command.Name -Icon "異"
    & $Command @invokeParams

}