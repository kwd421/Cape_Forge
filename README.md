# Cape Forge

A Swift tool for macOS that loads cursor sets, maps them to cursor roles, and exports Mousecape-compatible `.cape` files.

The primary runtime path is a standard macOS app.

- Reads `.ani` and `.cur` files from a folder chosen by the user.
- Automatically maps cursor files in the folder to cursor roles.
- Previews the loaded cursor for each role.
- Lets you manually override the file used for an individual role.
- Parses PNG frames and hotspots directly from ANI files.
- Exports `.cape` files that Mousecape can read.

Limitations:

- This app focuses on cursor conversion and `.cape` export.
- Applying the exported `.cape` file must be done in a separate app such as Mousecape.

## Run

```bash
./run_mac_mouse_cursor.command
```

## Package

```bash
./package_mac_mouse_cursor.command
open "./dist/Cape Forge.app"
```

## App Store Build

Open `CapeForge.xcodeproj` in Xcode, then archive the `CapeForge` target.

- App Sandbox is enabled.
- The app is configured to access only folders and save locations chosen by the user.
- For Mac App Store submission, use the Xcode Organizer archive flow.

## GitHub Pages

This repository is already structured for GitHub Pages with the `/docs` folder.

Suggested public URLs:

- Support URL: `https://kwd421.github.io/mac_mouse_cursor/`
- Privacy Policy URL: `https://kwd421.github.io/mac_mouse_cursor/privacy.html`
- Korean Support URL: `https://kwd421.github.io/mac_mouse_cursor/ko/`
- Korean Privacy Policy URL: `https://kwd421.github.io/mac_mouse_cursor/ko/privacy.html`

GitHub Pages setup:

1. Push the repository to GitHub.
2. Open the repository settings.
3. Go to `Pages`.
4. Set the source to `Deploy from a branch`.
5. Choose the `main` branch and the `/docs` folder.
6. Save and wait for the site to publish.

Support contact:

- `tonistark@naver.com`

## Notes

Both the runtime path and the packaging path are Swift app flows.
