# This PowerShell script automates tasks when the USB drive is connected to a Windows machine.

$usbDriveLetter = "E:"  # Change this to the appropriate drive letter

# Function to execute when the USB drive is connected
function Execute-Tasks {
    # Example task: Run a specific script or application
    Start-Process "$usbDriveLetter\your-script.ps1"  # Change to your script path
}

# Monitor for USB drive connection
while ($true) {
    if (Test-Path $usbDriveLetter) {
        Execute-Tasks
        break  # Exit the loop after executing tasks
    }
    Start-Sleep -Seconds 5  # Check every 5 seconds
}