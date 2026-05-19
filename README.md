# USB Boot Automation

## Overview
USB Boot Automation is a project designed to streamline the process of preparing USB drives for bootable media. This tool automates the detection, formatting, and flashing of USB drives, making it easier for users to create bootable USB drives for various operating systems.

## Features
- Detect connected USB devices
- Format USB drives to a specified file system
- Flash disk images onto USB drives
- PowerShell scripts for Windows automation

## Project Structure
```
usb-boot-automation
├── src
│   ├── cli.ts               # Command-line interface for user interaction
│   ├── index.ts             # Main entry point of the application
│   ├── usb
│   │   ├── detect.ts        # Functions to detect USB devices
│   │   ├── format.ts        # Function to format USB drives
│   │   └── flash.ts         # Function to flash images onto USB drives
│   ├── windows
│   │   └── autorun.ps1      # PowerShell script for Windows automation
│   └── types
│       └── index.ts         # TypeScript interfaces and types
├── scripts
│   └── prepare-usb.ps1      # PowerShell script to prepare USB drives
├── package.json              # npm configuration file
├── tsconfig.json             # TypeScript configuration file
└── README.md                 # Project documentation
```

## Installation
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd usb-boot-automation
   ```
3. Install the dependencies:
   ```
   npm install
   ```

## Usage
To use the USB Boot Automation tool, run the following command in your terminal:
```
npm start
```
Follow the prompts to detect, format, and flash your USB drive.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.