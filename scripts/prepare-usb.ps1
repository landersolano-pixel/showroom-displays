# This PowerShell script prepares the USB drive for use by formatting it and flashing necessary files.

param (
    [string]$DriveLetter,
    [string]$ImagePath
)

function Format-USBDrive {
    param (
        [string]$DriveLetter
    )
    
    # Format the USB drive
    $formatCommand = "format $DriveLetter: /FS:NTFS /Q /Y"
    Invoke-Expression $formatCommand
}

function Flash-Image {
    param (
        [string]$DriveLetter,
        [string]$ImagePath
    )
    
    # Flash the image onto the USB drive
    $flashCommand = "dd if='$ImagePath' of='$DriveLetter:' bs=4M status=progress"
    Invoke-Expression $flashCommand
}

# Main script execution
if (-Not (Test-Path $DriveLetter)) {
    Write-Host "The specified drive does not exist."
    exit
}

Format-USBDrive -DriveLetter $DriveLetter
Flash-Image -DriveLetter $DriveLetter -ImagePath $ImagePath

Write-Host "USB drive prepared successfully."