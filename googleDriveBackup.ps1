Function Parse-IniFile ($file) {
    $ini = @{}

    # Create a default section if none exist in the file. Like a java prop file.
    $section = "NO_SECTION"
    $ini[$section] = @{}

    switch -regex -file $file 
    {
        "^\[(.+)\]$" 
        {
            $section = $matches[1].Trim()
            $ini[$section] = @{}
        }
        "^\s*([^#].+?)\s*=\s*(.*)" 
        {
            $name,$value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";")))
            {
                $ini[$section][$name] = $value.Trim()
            }
        }
    }
    $ini
}

$config = Parse-IniFile("settings.ini")

$sourcePath = $config["General"]["SourcePath"]
$destinationPath = $config["General"]["DestinationPath"]
$maximumAgeOfBackupInDays = $config["General"]["MaximumAgeOfBackupsInDays"]
$stagingDirectory = $config["General"]["StagingDirectory"]

Write-Host "creating backup of $sourcePath"
$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$targetFileName = $destinationPath + "\" + $dateTime + ".zip"
Write-Host "target file is $targetFileName"

Write-Host "creating new backup"
if (Test-Path $stagingDirectory)
{
    Remove-Item -Path $stagingDirectory -Force -Recurse
}
Copy-Item -Path $sourcePath -Destination $stagingDirectory -Recurse
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory($stagingDirectory, $targetFileName)

Write-Host "checking old backups"
$allBackups = Get-ChildItem $destinationPath

$now = Get-Date

foreach ($backup in $allBackups)
{
    $lastWriteTime = $backup.LastWriteTime
    $ageAsTimespan = New-Timespan -Start $lastWriteTime -End $now
    $ageInDays = $ageAsTimespan.TotalDays
    Write-Host "backup $backup has an age of $($ageInDays.tostring('N2')) days"

    if ($ageInDays -le $maximumAgeOfBackupInDays)
    {
        Write-Host "file is younger than $maximumAgeOfBackupInDays days, keeping it"
    }
    else 
    {
        Write-Host "file is older than $maximumAgeOfBackupInDays days, deleting it"
        Remove-Item $backup.FullName
    }
}

Write-Host "press any key to close ..."
$keyPressResult = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")