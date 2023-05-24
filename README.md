# StrandedResources

StrandedResources is a tool designed to remove unused resources in Xcode projects. It is a helpful tool that can save time and space in your project by removing unnecessary resources.

## How to Setup the Scripts

Before running the scripts, you need to provide the correct permissions by running the following commands:

```
chmod +x localizationScript.swift
chmod +x imagesScript.swift
chmod +x retainCycleScript.swift
```

## Dependencies

These scripts assume that your project uses Swiftgen as a resource management tool. Install the dependency by running the following command:

```
brew install swiftgen
```

## Setup

Before running the scripts, you need to provide project details in the following files:

- **assetsURL.txt**: Paste the URL string for your assets folder in the txt file and save.
- **localizableUrl.txt**: Paste the URL string for your localization folder in the txt file and save.
- **projectsUrls.txt**: Paste the URL string for your project/source folders where you want to look for unused resources. Note that the URLs should be separated by a new line.

## Running the Scripts

To run the script, you need to specifically run the localization or images script separately.

### Localization

```
./localizationScript.swift search_strings
```

### Images

```
./imagesScript.swift search_strings search_images
```

After searching the localization/images, the script will ask for your permission to delete the unused resources. Note that you should make a copy of your project first if you cannot revert the changes done by the script.


## How the Scripts Work

The localizationScript.swift searches for unused localized strings in your Xcode project. It reads the strings files in your project's localization folder and compares them to the strings used in your code. If a string is found in the strings file but not used in the code, it is considered an unused resource and the script will prompt you to delete it.

The imagesScript.swift searches for unused image files in your Xcode project. It reads the image files in your project's assets folder and compares them to the images used in your code. If an image file is found in the assets folder but not used in the code, it is considered an unused resource and the script will prompt you to delete it.

The retainCycleScript.swift searches for retain cycles in your code. It uses the Xcode Instruments tool to find retain cycles and report them to you.

## Benefits of Using StrandedResources

- Saves time: Manually searching for unused resources can be time-consuming. StrandedResources automates the process and saves you time.
- Saves space: Unused resources can take up valuable space in your project. StrandedResources helps you identify and remove them, freeing up space in your project.
- Improves performance: Unused resources can slow down your project's performance. Removing them can help improve your project's performance.

## Conclusion

StrandedResources is a helpful tool for identifying and removing unused resources in your Xcode project. By using these scripts, you can save time, space, and improve your project's performance.
