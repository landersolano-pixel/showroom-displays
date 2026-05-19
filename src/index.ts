import { detectUSBDevices } from './usb/detect';
import { formatUSBDrive } from './usb/format';
import { flashUSBDrive } from './usb/flash';

async function main() {
    try {
        const devices = await detectUSBDevices();
        console.log('Detected USB devices:', devices);

        // Example usage: format the first detected USB drive
        if (devices.length > 0) {
            const drive = devices[0];
            await formatUSBDrive(drive.id, 'FAT32');
            console.log(`Formatted USB drive: ${drive.id}`);

            // Example usage: flash an image onto the USB drive
            const imagePath = 'path/to/image.iso'; // Replace with actual image path
            await flashUSBDrive(drive.id, imagePath);
            console.log(`Flashed image onto USB drive: ${drive.id}`);
        } else {
            console.log('No USB devices found.');
        }
    } catch (error) {
        console.error('An error occurred:', error);
    }
}

main();