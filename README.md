# QuickQuit

[![CI](https://github.com/choudharyjayesh668/QuickQuit/actions/workflows/ci.yml/badge.svg)](https://github.com/choudharyjayesh668/QuickQuit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

QuickQuit is a tiny native macOS utility. Press **Control+Shift+Q** and it asks every open app in your Dock to quit, the same way choosing **Quit** in each app would. Apps with unsaved work still show their usual save prompts. QuickQuit never force-quits anything.

> **Early release:** QuickQuit is distributed as source code that is built on your own Mac, whichever way you install it. The app is ad-hoc signed, not Developer ID signed or notarized. Read [Installation](#installation) and [Security and privacy](#security-and-privacy) before installing.

## Contents

- [Why QuickQuit](#why-quickquit)
- [Features](#features)
- [Supported platforms](#supported-platforms)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [Setup](#setup)
- [Usage](#usage)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Commands](#commands)
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
- Installs without `sudo`.

## Supported platforms

| Platform | Status |
| --- | --- |
| macOS 13 (Ventura) or newer, Apple silicon | Supported |
| macOS 13 (Ventura) or newer, Intel | Supported |
| Windows, Linux | Not supported. The installers stop with a message and change nothing |

QuickQuit is compiled with a macOS 13.0 deployment target. [GitHub Actions](.github/workflows/ci.yml) builds, tests, and installs it on macOS 15 (Apple silicon and Intel) and macOS 26 (Apple silicon). The automated checks never press the shortcut or quit real apps, and macOS 13 and 14 are not covered by CI.

## Prerequisites

- A Mac running macOS 13 or newer, where you are logged in at the desktop (not over SSH).
- Apple Command Line Tools with a Swift 6 compiler. Full Xcode is not required.
- For the npm installation only: [Node.js](https://nodejs.org/) 18 or newer, which includes npm.

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

There are three ways to install QuickQuit. They all do the same thing and can replace one another: each builds the app on your Mac and sets it up the same way.

### Option 1: npm

> **Not on the npm registry yet.** The package is ready, but the maintainer has not published it. Until it is published, `npm install -g quickquit` will not find it. Use Option 2 or 3, or install the package from a clone of this repository as shown under [Examples](#examples).

```sh
npm install -g quickquit
```

That one command installs the `quickquit` command and then, on macOS, builds, installs, and starts the app automatically. QuickQuit appears in the Dock when it is done. To confirm:

```sh
quickquit status
```

If QuickQuit did not start, npm skipped the setup step. Run it yourself:

```sh
quickquit install
```

npm skips the setup step when install scripts are turned off (`--ignore-scripts`), when a newer npm has not been told to allow them, or when you ran npm with `sudo`. Newer npm versions print a warning that `quickquit` has an install script; you can approve it up front with `npm install -g quickquit --allow-scripts=quickquit`.

Do not use `sudo` for QuickQuit's setup. If your npm needs `sudo` for global installs, run `sudo npm install -g quickquit` and then `quickquit install` as your normal user.

### Option 2: Terminal

```sh
git clone https://github.com/choudharyjayesh668/QuickQuit.git
cd QuickQuit
./Install\ QuickQuit.command
```

### Option 3: Download and double-click

1. On the [repository page](https://github.com/choudharyjayesh668/QuickQuit), click **Code → Download ZIP**.
2. Unzip the download.
3. Double-click **Install QuickQuit.command**.
4. If macOS blocks the file because it cannot verify the developer, first make sure you downloaded it from this repository. Then:
   - **macOS 15 or newer:** open **System Settings → Privacy & Security**, scroll down to **Security**, and click **Open Anyway**.
   - **macOS 13 or 14:** Control-click the file, choose **Open**, then click **Open** again.

### What installation does

Every option runs the same script, [`scripts/install.sh`](scripts/install.sh). In order, it:

1. Stops if the system is not macOS, if it is run as root, or if the Command Line Tools are missing. Nothing is changed in those cases.
2. Builds `QuickQuit.app` from the Swift source. With npm the build happens in a temporary folder that is deleted afterwards.
3. Chooses where to install: `/Applications` if you can write to it, otherwise `~/Applications`. It never asks for a password.
4. Stops any running copy of QuickQuit and unloads its LaunchAgent.
5. Deletes the previous `QuickQuit.app` from both Applications folders and copies the new one into place, so there is only ever one copy.
6. Writes the LaunchAgent `~/Library/LaunchAgents/local.quickquit.QuickQuit.plist`, replacing any earlier one.
7. Loads the LaunchAgent, which starts QuickQuit now, starts it at every login, and reopens it if it exits.

Because of steps 4 to 6, running any installer again is safe. You never end up with two apps, two LaunchAgents, or two running copies.

macOS may show a one-time **Background Items Added** notification. That is the LaunchAgent.

With npm, the files of the package itself (the `quickquit` command and the source code) go into npm's global folder. Run `npm root -g` to see where that is.

## Updating

| Installed with | To update |
| --- | --- |
| npm | `npm install -g quickquit@latest` |
| Terminal | `git pull`, then `./Install\ QuickQuit.command` |
| ZIP download | Download the ZIP again and double-click **Install QuickQuit.command** |

Updating runs the installation steps above again: the old app is stopped and replaced by the new build, and the LaunchAgent is rewritten. With npm, run `quickquit install` afterwards if npm skipped the setup step.

## Uninstalling

| Installed with | To remove |
| --- | --- |
| npm | `quickquit uninstall`, then `npm uninstall -g quickquit` |
| Terminal or ZIP download | Double-click **Uninstall QuickQuit.command**, or run `./Uninstall\ QuickQuit.command` |

Both run [`scripts/uninstall.sh`](scripts/uninstall.sh), which:

1. Unloads the LaunchAgent, so QuickQuit no longer starts at login or reopens.
2. Deletes `~/Library/LaunchAgents/local.quickquit.QuickQuit.plist`.
3. Quits QuickQuit.
4. Deletes `QuickQuit.app` from `/Applications` and `~/Applications`.
5. Deletes QuickQuit's one saved preference.

**With npm, run `quickquit uninstall` first.** npm does not run any script when a package is removed, so `npm uninstall -g quickquit` on its own removes only the `quickquit` command and leaves the app installed and running. If you already removed the package, either reinstall it and run `quickquit uninstall`, or use **Uninstall QuickQuit.command** from this repository.

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

## Keyboard shortcuts

| Shortcut | Where it works | What it does |
| --- | --- | --- |
| **Control+Shift+Q** | Everywhere | Asks every open Dock app to quit |
| **Command+Q** | While QuickQuit is the active app | Quits QuickQuit. The LaunchAgent reopens it within about 10 seconds |

Control+Shift+Q follows the physical position of the Q key on a US keyboard. On other keyboard layouts that key may carry a different label. The shortcut cannot be changed without editing the source.

## Commands

The npm package adds a `quickquit` command:

| Command | What it does |
| --- | --- |
| `quickquit install` | Builds, installs, and starts QuickQuit. Safe to run again; also repairs a broken installation |
| `quickquit uninstall` | Stops QuickQuit and removes the app and its LaunchAgent |
| `quickquit status` | Shows where the app is installed, its version, and whether it is loaded and running. Exits with code 0 only if everything is in place |
| `quickquit --version` | Prints the version of the npm package |
| `quickquit --help` | Shows the list of commands |

The command only manages the installation. It does not quit apps; only the keyboard shortcut does that.

## Examples

**End of the day.** Safari, Mail, Notes, and a TextEdit document with unsaved changes are open. Press Control+Shift+Q: Safari, Mail, and Notes quit, TextEdit asks whether to save, and Finder stays open.

**Check that QuickQuit is installed and running** (npm installation):

```sh
quickquit status
```

```text
App:          /Applications/QuickQuit.app (version 1.0.0)
LaunchAgent:  loaded (starts at login, reopens after it exits)
Running:      yes
```

**Check without the npm command:**

```sh
pgrep -lf QuickQuit
defaults read /Applications/QuickQuit.app/Contents/Info CFBundleShortVersionString
```

**Install the npm package from a clone, before it is published:**

```sh
git clone https://github.com/choudharyjayesh668/QuickQuit.git
cd QuickQuit
npm pack
npm install -g ./quickquit-1.0.0.tgz
```

**Install the command without setting up the app:**

```sh
QUICKQUIT_SKIP_POSTINSTALL=1 npm install -g quickquit
```

**Build and try it without installing:**

```sh
./build.sh
open build/QuickQuit.app
```

Only one copy runs at a time. If an installed copy is already running, the second copy exits immediately.

**Run the tests:**

```sh
npm test
```

## Project structure

```text
QuickQuit/
├── Sources/
│   ├── main.swift               App: global shortcut, single-instance handling, alerts
│   └── QuitPolicy.swift         Rules for which apps are asked to quit
├── scripts/
│   ├── install.sh               Builds, installs, and sets up the LaunchAgent
│   ├── uninstall.sh             Removes the app and the LaunchAgent
│   └── postinstall.js           Runs install.sh after a global npm install
├── bin/
│   └── quickquit.js             The quickquit command
├── lib/
│   └── quickquit.js             Logic behind the command and the npm postinstall step
├── Tests/
│   ├── main.swift               Unit tests for the quit policy
│   └── cli.test.js              Unit tests for the command and the postinstall step
├── build.sh                     Builds QuickQuit.app
├── test.sh                      Compiles and runs the Swift unit tests
├── Install QuickQuit.command    Double-click wrapper around scripts/install.sh
├── Uninstall QuickQuit.command  Double-click wrapper around scripts/uninstall.sh
├── package.json                 npm package definition and the version number
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

The `build/` folder is generated by the build and is not part of the repository. The npm package contains `Sources/`, `scripts/`, `bin/`, `lib/`, `build.sh`, `package.json`, this README, and the license.

## Troubleshooting

**`npm install -g quickquit` fails with "Unsupported platform" (EBADPLATFORM).**
QuickQuit only works on macOS. npm refuses to install it on Windows and Linux.

**`npm install -g quickquit` finished, but QuickQuit is not in the Dock.**
npm skipped the setup step. Run `quickquit install`. See [Option 1](#option-1-npm) for why this happens.

**npm warns that `quickquit` has install scripts "not yet covered by allowScripts".**
That is npm asking you to approve the setup step, which is described under [What installation does](#what-installation-does). Approve it with `npm install -g quickquit --allow-scripts=quickquit`, or ignore the warning and run `quickquit install` if the app did not start.

**"QuickQuit must not be set up as root or with sudo."**
Run `quickquit install` again without `sudo`. QuickQuit runs inside your own login session and never needs administrator rights.

**"Apple Command Line Tools (the Swift compiler) were not found."**
Install them with `xcode-select --install`, then run the installer again (`npm install -g quickquit`, `quickquit install`, or **Install QuickQuit.command**).

**"The build failed. QuickQuit needs a Swift 6 compiler."**
Update the Command Line Tools in **System Settings → General → Software Update**.

**"macOS could not load its LaunchAgent."**
The installer was run without a desktop session, for example over SSH. Log in at the Mac's screen and run the installer again.

**"Install QuickQuit.command" cannot be opened because the developer cannot be verified.**
See step 4 of [Option 3](#option-3-download-and-double-click), or use [Option 2](#option-2-terminal), which avoids this prompt.

**Nothing happens when I press Control+Shift+Q.**
Run `quickquit status` or `pgrep -lf QuickQuit`. If QuickQuit is not running, run the installer again. If it is running, another app may own the shortcut. QuickQuit shows an alert about this only once and then retries every 30 seconds; quit the other app or change its shortcut and QuickQuit takes over.

**QuickQuit does not start at login.**
Open **System Settings → General → Login Items** and make sure QuickQuit is allowed under **Allow in the Background**. Then run the installer again.

**QuickQuit comes back after I quit it.**
That is intended: the LaunchAgent reopens it. To stop it for good, [uninstall it](#uninstalling).

**I ran `npm uninstall -g quickquit` and QuickQuit is still running.**
npm cannot remove the app. See [Uninstalling](#uninstalling).

**An app did not quit.**
It may be waiting for you to answer a save prompt, or it may be a menu bar or background app, which QuickQuit leaves alone on purpose.

Still stuck? See [SUPPORT.md](SUPPORT.md).

## Security and privacy

- QuickQuit has no network or analytics code. It reads the list of running apps locally and sends them normal quit requests.
- It does not request Accessibility or Input Monitoring access, and nothing it does needs `sudo`.
- Every installer compiles the app on your Mac. The result is ad-hoc signed and not notarized, so only install it from source you trust.
- The npm package runs a `postinstall` script. For a global install on macOS it does exactly what is listed under [What installation does](#what-installation-does). For any other kind of install it does nothing. Set `QUICKQUIT_SKIP_POSTINSTALL=1` or use `--ignore-scripts` to turn it off.
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
- The open-source preparation of this repository (documentation, issue and pull request templates, unit tests, and CI workflow) and the npm packaging were done with Claude Code (Anthropic).

AI tools are assistants, not owners or maintainers. The maintainer decides what is merged and is responsible for the project.

Contributors may use AI tools too, and must say so in their pull request. See the [AI usage policy](CONTRIBUTING.md#ai-usage-policy).

## Credits

GPT (OpenAI) and Claude (Fable 5.2, Anthropic) assisted with development. See [CREDITS.md](CREDITS.md).

## License

QuickQuit is released under the [MIT License](LICENSE).

## Maintainer

QuickQuit is owned and maintained by **Jayesh Choudhary** ([@choudharyjayesh668](https://github.com/choudharyjayesh668)).
