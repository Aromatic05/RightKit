# RightKit for macOS

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Swift Version](https://img.shields.io/badge/Swift-6.x-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos)
[![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/Aromatic05/RightKit/issues)

**RightKit is a powerful, open-source enhancement tool for the macOS Finder context menu. It's designed to boost your file management efficiency by providing a fully customizable right-click menu.**

![RightKit Screenshot (placeholder)](https://via.placeholder.com/800x400.png?text=RightKit+UI+Screenshot)

## About The Project

RightKit supercharges the macOS Finder by replacing the standard right-click menu with a highly configurable one. It consists of a main settings application and a Finder Sync Extension. The initial version focuses on a robust "Create New File" feature (including from templates), while building a solid foundation for future additions like "Copy Path," "Cut File," and more.

### Built With

*   **Swift 6.x**
*   **SwiftUI** for the settings interface
*   **Finder Sync Extension** for seamless Finder integration
*   **App Groups** for data sharing between the app and the extension
*   **Security-Scoped Bookmarks** for persistent, secure access to user-defined folders

## Features

*   **Customizable Menu Structure:** Visually add, edit, delete, and reorder menu items through an intuitive drag-and-drop interface.
*   **Create New File:** Instantly create blank files with a specific extension (e.g., `.txt`, `.md`).
*   **Create from Template:** Designate a folder of templates and quickly create new documents from any of them directly within Finder.
*   **Real-time Updates:** Menu configuration changes apply instantly without needing to restart Finder.
*   **Modern & Secure:** Built with the latest Swift and macOS technologies to ensure stability and security.

### Planned Features (Roadmap)

*   [ ] **Copy File Path:** Copy the absolute or relative path of a file/folder.
*   [ ] **Cut & Paste:** A true cut-and-paste functionality for files and folders.
*   [ ] **Run Shell Scripts:** Execute custom shell scripts on selected files.
*   [ ] **Custom Icons:** Assign custom icons to menu items.
*   [ ] **Localization:** Support for multiple languages.

## Getting Started

To get a local copy up and running for development and testing, follow these simple steps.

### Prerequisites

*   macOS 14.0 or later
*   Xcode 16 or later
*   Swift 6.x

### Installation & Running

1.  **Clone the repo:**
    ```sh
    git clone https://github.com/Aromatic05/RightKit.git
    ```
2.  **Open the project in Xcode:**
    ```sh
    cd RightKit
    open RightKit.xcodeproj
    ```
3.  **Configure Signing & Capabilities:**
    *   In the project settings, select both the `RightKit` and `RightKitExtension` targets.
    *   Under the "Signing & Capabilities" tab, assign your developer team.
    *   Ensure both targets share the same App Group ID (e.g., `group.com.your-domain.RightKit`).

4.  **Run the `RightKit` main application scheme.** The app will launch.

5.  **Enable the Extension:**
    *   Go to **System Settings** > **Privacy & Security** > **Extensions**.
    *   Find "Finder Extensions" and enable `RightKitExtension`.
    *   Relaunch Finder if necessary (Option + Right-click on the Finder icon in the Dock and select "Relaunch").

## Usage

1.  **Launch the RightKit application.**
2.  Use the UI to configure your desired right-click menu layout. Add new items, create sub-menus, and assign actions like "Create Empty File."
3.  To use the "Create File from Template" feature, first set your template folder's path within the RightKit app. The app will automatically populate the context menu with your templates.
4.  Once configured, simply right-click in any Finder window or on the Desktop to see your new, powerful context menu in action!

## How It Works

RightKit is composed of two main components that work together:

1.  **The Main App (`RightKit.app`):** This is the user-facing settings panel. When you customize your menu, the configuration is saved as a `menu.json` file within a shared App Group container. It then sends a notification that the configuration has changed.

2.  **The Finder Extension (`RightKitExtension.appex`):** This extension runs silently in the background. It listens for right-clicks within Finder and for the update notifications from the main app. When triggered, it reads the `menu.json` from the shared container and dynamically builds the custom context menu.

This architecture ensures that the menu is always up-to-date and that the extension itself remains lightweight and efficient.

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

Don't forget to give the project a star! Thanks again!

## License

Distributed under the GNU General Public License v3.0. See `LICENSE.txt` for more information. [8, 12, 14]

## Contact

Aromatic - [@YourTwitterHandle](https://twitter.com/YourTwitterHandle) - email@example.com

Project Link: [https://github.com/Aromatic05/RightKit](https://github.com/Aromatic05/RightKit)
