## **Mac Saver Builder**

![Release](https://img.shields.io/badge/Release-v1.0-green)  ![macOS](https://img.shields.io/badge/macOS-14%2B-red)  ![Xcode](https://img.shields.io/badge/Xcode-16.0-blue)  ![Swift](https://img.shields.io/badge/Swift-5.9-orange)  ![License](https://img.shields.io/badge/License-MIT-yellow)

![App Banner](https://github.com/GetInfo-ACN/MacSaverBuilder/blob/main/Screenshots/App_Banner.png)

Screen savers are standard security controls used to limit access to a Mac and the user's session when the Mac is idle or left unattended. Mac Saver Builder is an innovative tool that allows you to create custom screen savers for macOS. This application caters to two primary user groups:

**IT Professionals (#MacAdmins):**

*   IT teams managing macOS devices (#MacAdmins) can use the app to easily create screen savers compliant with security standards (CIS, NIST, DISA STIG, etc.) across the organization.

**End Users:**

*   Designed for individuals who want to create unique screen savers tailored to their personal style.

The application takes **video files (.mp4, .mov)** and **small images (.jpg, .png)** and generates screen savers in .saver format. This output is suitable for both manual installation and MDM distribution. While **Mac Saver Builder** is a signed application, the .saver files generated by the app are unsigned.


## **Demo 🚀**

With Mac Saver Builder, simply drag and drop or select your video and image files to quickly generate .saver screen savers.

![App Demo](https://github.com/GetInfo-ACN/MacSaverBuilder/blob/main/Screenshots/App_Demo.gif)



## **Requirements ⚙️**

*   macOS 14 or higher
*   For MDM Deployment:
    *   Any MDM solution
    *   Developer signature, packaging solution, policy, and configuration


## **Download 📦**

Download the signed final version of the application:  
_(GitHub link will be placed here.)_  

Example (unsigned) generated Screen Saver  
_(GitHub link will be placed here.)_


## **Documentation 📝**

For more information about the features and usage of the application, visit our [wiki page](https://github.com/GetInfo-ACN/MacSaverBuilder/wiki) or refer to the following links:

[Jamf Pro Deployment](https://github.com/GetInfo-ACN/MacSaverBuilder/wiki/1.-Jamf-Pro-Deployment)

A step-by-step guide for deploying `.saver` screen savers via Jamf Pro (MDM).

[End User Installation](https://github.com/GetInfo-ACN/MacSaverBuilder/wiki/2.-End-User-Installation)

Instructions for the manual installation of screen savers for end users.

[Template Keynote](https://github.com/GetInfo-ACN/MacSaverBuilder/wiki/3.-Template-Keynote)

Pre-designed `Keynote` templates to assist in creating precise thumbnails and videos for screen savers.

[Troubleshooting and Support](https://github.com/GetInfo-ACN/MacSaverBuilder/wiki/4.-Troubleshooting-and-Support)

Tips for resolving issues or unexpected behaviors related to the Mac Saver Builder app and `.saver` outputs.


## **Known Issues ⚠️**

Since Apple began moving the native Screen Saver system to the .appex format, there have been some incompatibilities with the traditional .saver format. These incompatibilities can be more noticeable when end users create multiple .saver files. However, these issues are generally less common in MDM-managed single .saver deployments.

In the Screen Saver section, preview may sometimes appear as a black screen. Selecting a different screen saver and then returning to the previous one can resolve the preview issue. 

When multiple traditional .saver files exist, switching between them may cause instability. In such cases, restarting the Mac or using **Activity Monitor** to **“Force Quit”** the `legacyScreenSaver (Wallpaper)` process can fix the issue.


## **Privacy Policy 🔒**

We value your privacy. Mac Saver Builder does not collect, process, or send any personal data to third parties. The application runs locally on your device and stores your data only on your computer.


## **Support - Disclaimer 🛠️**

**GetInfo** created this application as a side project to provide additional value to our clients. The application is freely available and provided on an "as is" basis, without any warranties or guarantees.

While we welcome users to modify and enhance the application to suit their needs, please note that we are unable to provide support or address inquiries at this time.


## **License 🏷️**

This project is licensed under the MIT License. Please refer to the [LICENSE](https://github.com/GetInfo-ACN/MacSaverBuilder/blob/main/LICENSE) file for more details.


## **Contributor 👨‍💻**

This project was developed by [**Hüseyin Usta**](https://github.com/huseyinusta) as part of an initiative by **GetInfo**. Although the project was not created by a professional developer, it is built with care and aims to provide useful tools for macOS users.