import { exec } from 'child_process';
import { promisify } from 'util';

const execPromise = promisify(exec);

interface USBDevice {
    id: string;
    name: string;
    size: number;
}

export async function detectUSBDevices(): Promise<USBDevice[]> {
    try {
        const { stdout } = await execPromise('wmic logicaldisk where "drivetype=2" get deviceid, volumename, size /format:csv');
        const devices: USBDevice[] = parseUSBDevices(stdout);
        return devices;
    } catch (error) {
        console.error('Error detecting USB devices:', error);
        return [];
    }
}

function parseUSBDevices(data: string): USBDevice[] {
    const lines = data.trim().split('\n').slice(1);
    const devices: USBDevice[] = [];

    for (const line of lines) {
        const [id, name, size] = line.split(',');
        if (id && name && size) {
            devices.push({
                id: id.trim(),
                name: name.trim(),
                size: parseInt(size.trim(), 10),
            });
        }
    }

    return devices;
}