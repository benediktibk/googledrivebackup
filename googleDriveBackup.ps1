$sourcePath = "C:\Users\benedikt.schmidt\Google Drive"
$destinationPath = "U:\Backup\Google Drive"
$maximumAgeOfBackupInDays = 180

Write-Host "creating backup of $sourcePath"
$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$targetFileName = $destinationPath + "\" + $dateTime + ".zip"
Write-Host "target file is $targetFileName"

Write-Host "creating new backup"
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory($sourcePath, $targetFileName)

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