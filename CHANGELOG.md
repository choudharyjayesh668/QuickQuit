# Changelog

All notable changes to QuickQuit are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). No version has been tagged or released yet; the in-development version is 1.0.0.

## [Unreleased]

### Added

- macOS utility that registers Control+Shift+Q and asks regular Dock apps to quit normally, without force-quitting.
- LaunchAgent that starts QuickQuit at login and relaunches it after it exits.
- Installer and uninstaller scripts.
- Unit tests for the rules that decide which apps are asked to quit (`./test.sh`).
- GitHub Actions workflow that lints the shell scripts, runs the unit tests, and builds the app on macOS 15 (Apple silicon and Intel) and macOS 26.
- npm package `quickquit`. `npm install -g quickquit` builds, installs, and starts QuickQuit on macOS through a `postinstall` step that only acts on global installs. The package has not been published to the npm registry yet.
- `quickquit` command with `install`, `uninstall`, `status`, `--version`, and `--help`.
- Unit tests for the command and the `postinstall` step (`npm run test:cli`), and a CI job that installs the packed package globally, reinstalls it, and uninstalls it.
- `package.json` is the single source of truth for the version number.
- Contributor documentation: contribution guide with an AI usage policy, Contributor Covenant code of conduct, security policy, support guide, and issue and pull request templates.

### Changed

- The app is compiled with an explicit macOS 13.0 deployment target, so the binary matches the minimum version declared in `Info.plist`.
- The app version is now the three-part semantic version `1.0.0` (previously `1.0`).
- The install and uninstall logic moved to `scripts/install.sh` and `scripts/uninstall.sh`. `Install QuickQuit.command` and `Uninstall QuickQuit.command` are now thin wrappers around them and behave as before.
- The installers stop with a clear message on a system other than macOS, when run as root, when Apple Command Line Tools are missing, and when the LaunchAgent cannot be loaded because there is no desktop session.
- A failed build explains that a Swift 6 compiler is required and shows the installed compiler version.
- When reinstalling, the installer waits for launchd to finish unloading the previous LaunchAgent before loading the new one, to avoid a possible failure if the two steps overlap.
- The installer removes a `QuickQuit.app` left in the other Applications folder by an earlier install, so only one copy exists.
- The installer reports whether QuickQuit actually started, and the uninstaller reports anything it could not remove.
- `build.sh` and `test.sh` write to `QUICKQUIT_BUILD_DIR` when it is set.

[Unreleased]: https://github.com/choudharyjayesh668/QuickQuit/commits/main
