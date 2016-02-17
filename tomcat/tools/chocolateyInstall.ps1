$PFFolder = if (Get-ProcessorBits -eq 64) { "$Env:ProgramFiles" } else { "$Env:ProgramFiles(x86)" };

$options = @{
    version = '8.0.30';
    unzipLocation = (Join-Path $PFFolder "Apache Software Foundation\tomcat");
    serviceName = 'Tomcat8';
}

$unzipParameters = @{
    packageName = 'tomcat';
    url = "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.30/bin/apache-tomcat-8.0.30-windows-x86.zip";
    url64bit = "http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.30/bin/apache-tomcat-8.0.30-windows-x64.zip";
    checksum = '84fe2d5237c8569ef748700d1ac1dfba';
    checksumType = 'md5';
    checksum64 = 'a4121b78c8eb12c7af0b7fad6fec39d6';
    checksumType64 = 'md5';
}

$catalinaHome = Join-Path $options['unzipLocation'] "apache-tomcat-$($options['version'])";
Install-ChocolateyEnvironmentVariable 'CATALINA_HOME' "$catalinaHome"
$service = Get-Service | ? Name -eq $options['serviceName']
if ($service -ne $null) {
  Stop-Service $service
}

$binPath = Join-Path $catalinaHome 'bin'
if ((Test-Path $binPath) -and ($service -ne $null)) {
  Push-Location $binPath
  Start-ChocolateyProcessAsAdmin ".\service.bat uninstall $($options['serviceName'])"
  Pop-Location
}

if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\ChocolateyHelpers.ps1"

Set-ChocolateyPackageOptions $options
Install-ChocolateyZipPackage @unzipParameters -UnzipLocation $options['unzipLocation']

Push-Location $binPath
Start-ChocolateyProcessAsAdmin ".\service.bat install $($options['serviceName'])"
Pop-Location

Export-CliXml -Path (Join-Path $PSScriptRoot 'options.xml') -InputObject $options

Get-Service |? Name -eq $options['serviceName'] | Start-Service
