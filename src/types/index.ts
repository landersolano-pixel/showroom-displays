export interface USBDevice {
    id: string;
    name: string;
    size: number; // Size in bytes
    isMounted: boolean;
}

export interface FormatOptions {
    fileSystem: 'FAT32' | 'NTFS' | 'exFAT';
    quickFormat: boolean;
}