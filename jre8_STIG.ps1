# Params
Param (
    [Boolean]$ClassifiedNetwork # Skips tests that are NA for classified systems if true
)

# Store the location of the JAVA_HOME variable where the JRE should be stored
Write-Host "**********************************" -ForegroundColor Yellow
Write-Host "Checking for %JAVA_HOME% Variable" -ForegroundColor Yellow
Write-Host "**********************************" -ForegroundColor Yellow
$java_loc = [Environment]::GetEnvironmentVariable("JAVA_HOME")
IF ($java_loc -eq $NULL)
    {
        Write-Host "Terminating..." -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "No %JAVA_HOME% Variable Exists" -BackgroundColor Red -ForegroundColor Yellow
        Break
    }
Write-Host ""
Write-Host "%JAVA_HOME% Variable Found" -ForegroundColor Yellow
Write-Host "%JAVA_HOME% is located at $java_loc" -ForegroundColor Yellow

# Add the location where property files are typically stored
$java_lib = "$java_loc\lib"

# Find and store the deployment.config file
Write-Host ""
Write-Host "Searching the lib folder for config file..." -ForegroundColor Yellow
IF ((Test-Path -Path $java_lib\deployment.config) -eq $FALSE)
    {
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "Terminating..." -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "No deployment.config file exists" -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -BackgroundColor Red -ForegroundColor Yellow
        Break
    }
Write-Host "Config file found!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Searching config file for deployment.properties file location..." -ForegroundColor Yellow
$java_deploy_config = Select-String -Pattern 'deployment.system.config=' -Path $java_lib\deployment.config
IF ($java_deploy_config -eq $NULL)
    {
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "Terminating..." -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "No deployment.properties entry exists" -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -BackgroundColor Red -ForegroundColor Yellow
        Break
    }
$deploy_file_loc = ($java_deploy_config.line).Substring(25).Replace("file:///","").Replace("/","\")
Write-Host ""
Write-Host "deployment.properties file found!" -ForegroundColor Yellow
$deploy_file = Get-Content -Path $deploy_file_loc.Substring(1).Substring(0,($deploy_file_loc.Length-2))

# Load the JSON and copy to custom object
Write-Host ""
Write-Host "Loading the JSON file to perform checks..." -ForegroundColor Yellow
$json_obj = Get-Content -Path .\jre8_Vulns.json | ConvertFrom-Json
IF ($json_obj -eq $NULL)
    {
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "Terminating..." -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "No JSON file found..." -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -BackgroundColor Red -ForegroundColor Yellow
        Break
    }

# Perform the checks
Write-Host ""
Write-Host "Performing automated checks..." -ForegroundColor Yellow
Foreach ($stigItem in $json_obj.stigItems)
    {
        Write-Host ""
        Write-Host $stigItem.vulnID -ForegroundColor Yellow
        $fail_Count = 0
        IF ($ClassifiedNetwork -eq $TRUE)
            {
                IF ($stigItem.classificationSkip -eq "true")
                    {
                        Write-Host "Skipping... Check is N/A on classified systems."
                    }
                ELSE
                    {
                        Foreach ($check in $stigItem.checks)
                            {
                                $check_Num = $check_Num+1
                                    IF ((Select-String -Pattern $check -InputObject $deploy_file) -eq $False)
                                        {
                                            Write-Host "Check item $check_Num failed!" -BackgroundColor Red -ForegroundColor Yellow
                                            $fail_count = $fail_Count+1
                                        }
                                    ELSE
                                        {
                                            Write-Host "Check item $check_Num passed."
                                        }
                            }
                        $check_Num = 0
                    }
            }
        ELSE
            {
                Foreach ($check in $stigItem.checks)
                    {
                        $check_Num = $check_Num+1
                            IF ((Select-String -Pattern $check -InputObject $deploy_file) -eq $False)
                                {
                                    Write-Host "Check item $check_Num failed!" -BackgroundColor Red -ForegroundColor Yellow
                                    $fail_count = $fail_Count+1
                                }
                            ELSE
                                {
                                    Write-Host "Check item $check_Num passed."
                                }
                    }
                $check_Num = 0
            }
    }
Write-Host ""
Write-Host "**********************************************" -ForegroundColor Yellow
Write-Host "$fail_Count items failed the automated checks" -ForegroundColor Yellow
Write-Host "**********************************************" -ForegroundColor Yellow