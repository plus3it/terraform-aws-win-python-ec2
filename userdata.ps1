
$RMUser = "${adm_user}"
$PypiUrl = "${pypi_url}"

# log file
$UserdataLogFile = "${userdata_log}"
If(-not (Test-Path "$UserdataLogFile"))
{
  New-Item "$UserdataLogFile" -ItemType "file" -Force
}

# directory needed by logs and for various other purposes
$TempDir = "${temp_dir}"
If(-not (Test-Path "$TempDir"))
{
  New-Item "$TempDir" -ItemType "directory" -Force
}
cd $TempDir

function Write-Tfi
## Writes messages to a Terrafirm log file. Second param is success/failure related to msg.
{

  Param
  (
    [String]$Msg,
    $Success = $null
  )

  # result is succeeded or failed or nothing if success is null
  If( $Success -ne $null )
  {
    If ($Success)
    {
      $OutResult = ": Succeeded"
    }
    Else
    {
      $OutResult = ": Failed"
    }
  }

  "$(Get-Date): $Msg $OutResult" | Out-File "$UserdataLogFile" -Append -Encoding utf8
}

function Test-Command
## Tests commands and handles/retries errors that result.
{
  #
  Param (
    [Parameter(Mandatory=$true)][string]$Test,
    [Parameter(Mandatory=$false)][int]$Tries = 1,
    [Parameter(Mandatory=$false)][int]$SecondsDelay = 2
  )
  $TryCount = 0
  $Completed = $false
  $MsgFailed = "Command [{0}] failed" -f $Test
  $MsgSucceeded = "Command [{0}] succeeded." -f $Test

  While (-not $Completed)
  {
    Try
    {
      $Result = @{}
      # Invokes commands and in the same context captures the $? and $LastExitCode
      Invoke-Expression -Command ($Test+';$Result = @{ Success = $?; ExitCode = $LastExitCode }')
      If (($False -eq $Result.Success) -Or ((($Result.ExitCode) -ne $null) -And (0 -ne ($Result.ExitCode)) ))
      {
        Throw $MsgFailed
      }
      Else
      {
        Write-Tfi $MsgSucceeded
        $Completed = $true
      }
    }
    Catch
    {
      $TryCount++
      If ($TryCount -ge $Tries)
      {
        $Completed = $true
        $ErrorMessage = [String]$_.Exception + "Invocation Info: " + ($PSItem.InvocationInfo | Format-List * | Out-String)
        Write-Tfi $ErrorMessage
        Write-Tfi ("Command [{0}] failed the maximum number of {1} time(s)." -f $Test, $Tries)
        Write-Tfi ("Error code (if available): {0}" -f ($Result.ExitCode))
        Throw ("Command [{0}] failed" -f $Test)
      }
      Else
      {
        Write-Tfi ("Command [{0}] failed. Retrying in {1} second(s)." -f $Test, $SecondsDelay)
        Start-Sleep $SecondsDelay
      }
    }
  }
}

function Test-DisplayResult
## Call this function with $? to log the outcome and throw errors.
{
  Param
  (
    [String]$Msg,
    $Success = $null
  )

  Write-Tfi $Msg $Success
  If (-not $Success)
  {
    throw "$Msg : FAILED"
  }
}

function Open-WinRM
## Open WinRM for access by, for example, a Terraform remote-exec provisioner.
{
  # initial winrm setup
  Start-Process -FilePath "winrm" -ArgumentList "quickconfig -q"
  Write-Tfi "WinRM quickconfig" $?
  Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service @{AllowUnencrypted=`"true`"}" -Wait
  Write-Tfi "Open winrm/unencrypted" $?
  Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service/auth @{Basic=`"true`"}" -Wait
  Write-Tfi "Open winrm/auth/basic" $?
  Start-Process -FilePath "winrm" -ArgumentList "set winrm/config @{MaxTimeoutms=`"1900000`"}"
  Write-Tfi "Set winrm timeout" $?
}

function Close-Firewall
## Close the local firewall to WinRM traffic.
{
  # close the firewall
  netsh advfirewall firewall add rule name="WinRM in" protocol=tcp dir=in profile=any localport=5985 remoteip=any localip=any action=block
  Write-Tfi "Close firewall" $?
}

function Open-Firewall
## Open the local firewall to WinRM traffic.
{
  # open firewall for winrm - rule was added previously, now we modify it with "set"
  netsh advfirewall firewall set rule name="WinRM in" new action=allow
  Write-Tfi "Open firewall" $?
}

function Set-Password
## Changes a system user's password.
{
  Param
  (
    [Parameter(Mandatory=$true)][string]$User,
    [Parameter(Mandatory=$true)][string]$Pass
  )
  # Set Administrator password, for logging in before wam changes Administrator account name
  $Admin = [adsi]("WinNT://./$User, user")
  If ($Admin.Name)
  {
    $Admin.psbase.invoke("SetPassword", $Pass)
    Write-Tfi "Set $User password" $?
  }
  Else
  {
    Write-Tfi "Unable to set password because user ($User) was not found."
  }
  
}

function Invoke-CmdScript
## Invoke the specified batch file with params, and propagate env var changes back to 
## PowerShell environment that called it.
##
## Recipe from "Windows PowerShell Cookbook by Lee Holmes"
{

  Param
  (
    [string] $script,
    [string] $parameters
  )

  $tempFile = [IO.Path]::GetTempFileName()

  ## Store the output of cmd.exe. We also ask cmd.exe to output
  ## the environment table after the batch file completes
  cmd /c " `"$script`" $parameters && set > `"$tempFile`" "

  ## Go through the environment variables in the temp file.
  ## For each of them, set the variable in our local environment.
  Get-Content $tempFile | Foreach-Object {
      if($_ -match "^(.*?)=(.*)$")
      {
          Set-Content "env:\$($matches[1])" $matches[2]
      }
  }

  Remove-Item $tempFile
}

# Location to save files.
$SaveDir = $${Env:Temp}

function Install-Msi {
  Param( [String]$Installer, [String[]]$InstallerArgs )
  $Arguments = @()
  $Arguments += "/i"
  $Arguments += "`"$${Installer}`""
  $Arguments += $InstallerArgs
  Write-Tfi "Installing $Installer"
  $ret = Start-Process "msiexec.exe" -ArgumentList $${Arguments} -NoNewWindow -PassThru -Wait
}

function Install-Exe {
  Param( [String]$Installer, [String[]]$InstallerArgs )
  Write-Tfi "Installing $Installer"
  $ret = Start-Process "$${Installer}" -ArgumentList $${InstallerArgs} -NoNewWindow -PassThru -Wait
}

function Download-File {
  Param( [string]$Url, [string]$SavePath )
  # Download a file, if it doesn't already exist.
  if( !(Test-Path $${SavePath} -PathType Leaf) ) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::SystemDefault
    $SecurityProtocolTypes = @([Net.SecurityProtocolType].GetEnumNames())
    if ("Tls11" -in $SecurityProtocolTypes) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls11
    }
    if ("Tls12" -in $SecurityProtocolTypes) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    (New-Object System.Net.WebClient).DownloadFile($${Url}, $${SavePath})
    Write-Tfi "Downloaded $${Url} to $${SavePath}"
  }
}

function Reset-EnvironmentVariables {
  foreach( $Level in "Machine", "User" ) {
    [Environment]::GetEnvironmentVariables($${Level}).GetEnumerator() | % {
      # For Path variables, append the new values, if they're not already in there.
      if($_.Name -match 'Path$') {
        $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select -unique) -join ';'
      }
      $_
    } | Set-Content -Path { "Env:$($_.Name)" }
  }
}
 
function Test-URI {
  Param( [string]$Url )
   
  Write-Tfi "Testing $Url"
  Try {
    #hash table of parameter values for Invoke-Webrequest
    $paramHash = @{
      UseBasicParsing = $True
      DisableKeepAlive = $True
      Uri = $Url
      Method = 'Head'
      ErrorAction = 'stop'
      TimeoutSec = 15
    }
    $test = Invoke-WebRequest @paramHash

    if ($test.statuscode -eq 200) {
      $True
    }
  }
  Catch {
    Write-Tfi ("Failed: {0}" -f $_.exception)
    $False
  }
}

function Install-Python {

  # python 2 named differently that python 3
  if (!( Test-URI -Url $${PythonUrl} )) {
    $${PythonUrl} = $${PythonUrl} -replace "-amd64.exe",".amd64.msi"
  }

  $PythonFile = "$${SaveDir}\$($${PythonUrl}.split("/")[-1])"

  Download-File -Url $${PythonUrl} -SavePath $${PythonFile}

  if ($PythonFile -match "^.*msi$") {
    $Arguments = @()
    $Arguments += "/qn"
    $Arguments += "ALLUSERS=1"
    $Arguments += "ADDLOCAL=ALL"
    Install-Msi -Installer $${PythonFile} -InstallerArgs $${Arguments}
  }
  elseif ($PythonFile -match "^.*exe$") {
    $Arguments = @()
    $Arguments += "/quiet"
    $Arguments += "InstallAllUsers=1"
    $Arguments += "PrependPath=1"
    Install-Exe -Installer $${PythonFile} -InstallerArgs $${Arguments}
  }

  Write-Tfi "Installed Python"
}

function Install-Git {
  $GitFile = "$${SaveDir}\$($${GitUrl}.split("/")[-1])"

  Download-File -Url $${GitUrl} -SavePath $${GitFile}

  $Arguments = @()
  $Arguments += "/SILENT"
  $Arguments += "/NOCANCEL"
  $Arguments += "/NORESTART"
  $Arguments += "/SAVEINF=$${SaveDir}\git_params.txt"
  Install-Exe -Installer $${GitFile} -InstallerArgs $${Arguments}

  Write-Tfi "Installed Git"
}

function Install-PythonGit
{
  $global:PythonUrl = "${python_url}"
  $global:GitUrl = "${git_url}"

  # Install Python
  Write-Tfi "Python will be installed from $${PythonUrl}"
  Install-Python

  if( $${GitUrl} ) {
    # Download and install git
    Write-Tfi "Git will be installed from $${GitUrl}"
    Install-Git
  }

  Reset-EnvironmentVariables
  Write-Tfi "Reset the PATH environment for this shell"

  if ("$Env:TEMP".TrimEnd("\") -eq "$${Env:windir}\System32\config\systemprofile\AppData\Local\Temp") {
    $Env:TEMP, $Env:TMP = "$${Env:windir}\Temp", "$${Env:windir}\Temp"
    Write-Tfi "Forced TEMP envs to $${Env:windir}\Temp"
  }

  Write-Tfi "Installed Python/Git"
}

Set-Password -User "Administrator" -Pass "${adm_pass}"

Close-Firewall

# Use TLS, as github won't do SSL now
[Net.ServicePointManager]::SecurityProtocol = "Ssl3, Tls, Tls11, Tls12"

# install 7-zip for use with artifacts - download fails after wam install, fyi
(New-Object System.Net.WebClient).DownloadFile("${seven_zip_url}", "$TempDir\7z-install.exe")
Invoke-Expression -Command "$TempDir\7z-install.exe /S /D='C:\Program Files\7-Zip'" -ErrorAction Continue

Try {

    Write-Tfi "Start install"
  
    # time wam install
    $StartDate=Get-Date
    
    Install-PythonGit
  
    $EndDate = Get-Date
    Write-Tfi ("Install took {0} seconds." -f [math]::Round(($EndDate - $StartDate).TotalSeconds))
    Write-Tfi "End install"
}
Catch
{
  $ErrorMessage = [String]$_.Exception + "Invocation Info: " + ($PSItem.InvocationInfo | Format-List * | Out-String)
  Write-Tfi ("*** ERROR caught ($Stage) ***")
  Write-Tfi $ErrorMessage
}

Open-WinRM
Open-Firewall

