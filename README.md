# QuickQuit

[![CI](https://github.com/choudharyjayesh668/QuickQuit/actions/workflows/ci.yml/badge.svg)](https://github.com/choudharyjayesh668/QuickQuit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

QuickQuit is a tiny native macOS utility. Press **Control+Shift+Q** and it asks every open app in your Dock to quit, the same way choosing **Quit** in each app would. Apps with unsaved work still show their usual save prompts. QuickQuit never force-quits anything.

> **Early release:** QuickQuit is distributed as source code that is built on your own Mac. The app is ad-hoc signed, not Developer ID signed or notarized. Read [Installation](#installation) and [Security and privacy](#security-and-privacy) before installing.

## Contents

- [Why QuickQuit](#why-quickquit)
- [Features](#features)
- [Supported platforms](#supported-platforms)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Examples](#examples)
- [Project structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Security and privacy](#security-and-privacy)
- [Contributing](#contributing)
- [AI usage disclosure](#ai-usage-disclosure)
- [Credits](#credits)
- [License](#license)
- [Maintainer](#maintainer)

## Why QuickQuit

At the end of a work session you may have a dozen apps open. macOS has no built-in shortcut to close them all, so you quit each one by hand. QuickQuit gives you one shortcut that asks all of them to quit at once, without risking unsaved work.

## Features

- Registers **Control+Shift+Q** as a global keyboard shortcut.
- Sends a normal quit request to every running app that appears in the Dock.
- Lets each app show its standard save prompt or cancel quitting. Nothing is force-quit.
- Never asks Finder, the Dock, SystemUIServer, loginwindow, or QuickQuit itself to quit.
- Leaves menu bar utilities and background helpers alone.
- Starts at login and reopens itself if it exits, using a macOS LaunchAgent.
- If another app already uses the shortcut, shows one alert, keeps running, and retries every 30 seconds.
- Has no network code, no analytics, and needs no Accessibility or Input Monitoring permission.

## Supported platforms

| Platform | Status |
| --- | --- |
| macOS 13 (Ventura) or newer, Apple silicon | Supported |
| macOS 13 (Ventura) or newer, Intel | Supported |
| Windows, Linux | Not supported |

QuickQuit is compiled with a macOS 13.0 deployment target. Every push is built and unit-tested by [GitHub Actions](.github/workflows/ci.yml) on macOS 15 (Apple silicon and Intel) and macOS 26 (Apple silicon). The automated checks do not press the shortcut or quit real apps, and macOS 13 and 14 are not covered by CI.

## Prerequisites

- A Mac running macOS 13 or newer.
- Apple Command Line Tools with a Swift 6 compiler. Full Xcode is not required.
- Git, if you install with Terminal. It is included in the Command Line Tools.

Open **Terminal** (press Command+Space, type `Terminal`, press Return) and check your tools:

```sh
swift --version
xcode-select -p
```

If either command fails, install the Command Line Tools and follow the prompt that appears:

```sh
xcode-select --install
```

If `swift --version` shows a version older than 6, update the Command Line Tools in **System Settings → General → Software Update**.

## Installation

### Option 1: Terminal (recommended)

```sh
git clone https://github.com/choudharyjayesh668/QuickQuit.git
cd QuickQuit
./Install\ QuickQuit.command
```

### Option 2: Download and double-click

1. On the [repository page](https://github.com/choudharyjayesh668/QuickQuit), click **Code → Download ZIP**.
2. Unzip the download.
3. Double-click **Install QuickQuit.command**.
4. If macOS blocks the file because it cannot verify the developer, first make sure you downloaded it from this repository. Then:
   - **macOS 15 or newer:** open **System Settings → Privacy & Security**, scroll down to **Security**, and click **Open Anyway**.
   - **macOS 13 or 14:** Control-click the file, choose **Open**, then click **Open** again.

### What the installer does

1. Builds `QuickQuit.app` from source with `build.sh`.
2. Copies it to `/Applications`, or to `~/Applications` if `/Applications` is not writable.
3. Creates the LaunchAgent `~/Library/LaunchAgents/local.quickquit.QuickQuit.plist` so QuickQuit starts at login and reopens after it exits.
4. Starts QuickQuit.

macOS may show a one-time **Background Items Added** notification. That is the LaunchAgent.

### Updating

Get the newer source (`git pull`, or download the ZIP again) and run **Install QuickQuit.command** again. It replaces the installed app and refreshes the LaunchAgent.

### Uninstalling

Double-click **Uninstall QuickQuit.command**, or run it from Terminal:

```sh
./Uninstall\ QuickQuit.command
```

It stops QuickQuit, removes the LaunchAgent, deletes the app from `/Applications` and `~/Applications`, and clears QuickQuit's saved preference.

## Setup

QuickQuit needs no configuration and asks for no permissions. After installation it is already running: look for its icon in the Dock.

If you added QuickQuit under **System Settings → General → Login Items** yourself, remove that entry. The LaunchAgent already handles startup.

## Usage

1. Save your work.
2. Press **Control+Shift+Q**.
3. Each open Dock app receives a normal quit request. Apps with unsaved changes ask what to do, exactly as if you had quit them yourself.

Things to know:

- QuickQuit has no window. It appears in the Dock while it is running.
- The shortcut only works while QuickQuit is running.
- An app can refuse or cancel a quit request. QuickQuit does not override that.
- QuickQuit is not published on npm. Install it with the steps above.

## Keyboard shortcuts

| Shortcut | Where it works | What it does |
| --- | --- | --- |
| **Control+Shift+Q** | Everywhere | Asks every open Dock app to quit |
| **Command+Q** | While QuickQuit is the active app | Quits QuickQuit. The LaunchAgent reopens it within about 10 seconds |

Control+Shift+Q follows the physical position of the Q key on a US keyboard. On other keyboard layouts that key may carry a different label. The shortcut cannot be changed without editing the source.

## Examples

**End of the day.** Safari, Mail, Notes, and a TextEdit document with unsaved changes are open. Press Control+Shift+Q: Safari, Mail, and Notes quit, TextEdit asks whether to save, and Finder stays open.

**Check that QuickQuit is running:**

```sh
pgrep -lf QuickQuit
```

**Check the installed version:**

```sh
defaults read /Applications/QuickQuit.app/Contents/Info CFBundleShortVersionString
```

**Build and try it without installing:**

```sh
./build.sh
open build/QuickQuit.app
```

Only one copy runs at a time. If an installed copy is already running, the second copy exits immediately.

**Run the unit tests:**

```sh
./test.sh
```

## Project structure

```text
QuickQuit/
├── Sources/
│   ├── main.swift               App: global shortcut, single-instance handling, alerts
│   └── QuitPolicy.swift         Rules for which apps are asked to quit
├── Tests/
│   └── main.swift               Unit tests for the quit policy
├── build.sh                     Builds build/QuickQuit.app
├── test.sh                      Compiles and runs the unit tests
├── Install QuickQuit.command    Builds, installs, and sets up the LaunchAgent
├── Uninstall QuickQuit.command  Removes the app and the LaunchAgent
├── package.json                 Project metadata and version number (not published to npm)
├── .github/                     Issue and pull request templates, CI workflow, Dependabot
├── CHANGELOG.md                 Notable changes
├── CONTRIBUTING.md              How to contribute, AI usage policy
├── CODE_OF_CONDUCT.md           Community standards
├── SECURITY.md                  How to report vulnerabilities
├── SUPPORT.md                   Where to get help
├── CREDITS.md                   Acknowledgements
├── CITATION.cff                 Citation metadata
└── LICENSE                      MIT License
```

The `build/` folder is generated by the build and is not part of the repository.

## Troubleshooting

**"Install QuickQuit.command" cannot be opened because the developer cannot be verified.**
See step 4 of [Option 2](#option-2-download-and-double-click), or use the [Terminal install](#option-1-terminal-recommended), which avoids this prompt.

**"The Swift compiler was not found."**
Install the Command Line Tools with `xcode-select --install`, then run the installer again.

**The build fails with a Swift language version error.**
QuickQuit needs a Swift 6 compiler. Update the Command Line Tools in **System Settings → General → Software Update**.

**Nothing happens when I press Control+Shift+Q.**
Run `pgrep -lf QuickQuit`. If nothing is printed, QuickQuit is not running: run the installer again. If it is running, another app may own the shortcut. QuickQuit shows an alert about this only once and then retries every 30 seconds; quit the other app or change its shortcut and QuickQuit takes over.

**QuickQuit does not start at login.**
Open **System Settings → General → Login Items** and make sure QuickQuit is allowed under **Allow in the Background**. Then run the installer again.

**QuickQuit comes back after I quit it.**
That is intended: the LaunchAgent reopens it. To stop it for good, run **Uninstall QuickQuit.command**.

**An app did not quit.**
It may be waiting for you to answer a save prompt, or it may be a menu bar or background app, which QuickQuit leaves alone on purpose.

Still stuck? See [SUPPORT.md](SUPPORT.md).

## Security and privacy

- QuickQuit has no network or analytics code. It reads the list of running apps locally and sends them normal quit requests.
- It does not request Accessibility or Input Monitoring access.
- The installer compiles the app on your Mac. The result is ad-hoc signed and not notarized, so only install it from source you trust.
- To report a vulnerability, follow [SECURITY.md](SECURITY.md). Please do not open a public issue for security problems.

## Contributing

Bug reports, feature requests, and pull requests are welcome.

- Read [CONTRIBUTING.md](CONTRIBUTING.md) for setup, workflow, and coding standards.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- [Report a bug](https://github.com/choudharyjayesh668/QuickQuit/issues/new?template=bug_report.yml) or [request a feature](https://github.com/choudharyjayesh668/QuickQuit/issues/new?template=feature_request.yml).

Every change must keep the core safety behavior: ask apps to quit normally, never force-quit, and keep essential system apps excluded.

## AI usage disclosure

QuickQuit is developed with AI assistance, and the project is open about it:

- GPT (OpenAI) and Claude (Anthropic) assisted with implementation and documentation, as recorded in [CREDITS.md](CREDITS.md).
- The open-source preparation of this repository (documentation, issue and pull request templates, unit tests, and CI workflow) was done with Claude Code (Anthropic).

AI tools are assistants, not owners or maintainers. The maintainer decides what is merged and is responsible for the project.

Contributors may use AI tools too, and must say so in their pull request. See the [AI usage policy](CONTRIBUTING.md#ai-usage-policy).

## Credits

GPT (OpenAI) and Claude (Fable 5.2, Anthropic) assisted with development. See [CREDITS.md](CREDITS.md).

## License

QuickQuit is released under the [MIT License](LICENSE).

## Maintainer

QuickQuit is owned and maintained by **Jayesh Choudhary** ([@choudharyjayesh668](https://github.com/choudharyjayesh668)).
