import { Command } from 'commander';
import { detectUSBDevices } from './usb/detect';
import { formatUSBDrive } from './usb/format';
import { flashUSBDrive } from './usb/flash';

const program = new Command();

program
  .version('1.0.0')
  .description('USB Boot Automation Tool');

program
  .command('detect')
  .description('Detect connected USB devices')
  .action(async () => {
    const devices = await detectUSBDevices();
    console.log('Connected USB Devices:', devices);
  });

program
  .command('format <drive>')
  .description('Format a USB drive')
  .option('-f, --filesystem <type>', 'Specify the filesystem type (e.g., FAT32, NTFS)', 'FAT32')
  .action(async (drive, options) => {
    await formatUSBDrive(drive, options.filesystem);
    console.log(`Drive ${drive} formatted to ${options.filesystem}`);
  });

program
  .command('flash <drive> <image>')
  .description('Flash an image onto a USB drive')
  .action(async (drive, image) => {
    await flashUSBDrive(drive, image);
    console.log(`Flashed ${image} onto drive ${drive}`);
  });

program.parse(process.argv);