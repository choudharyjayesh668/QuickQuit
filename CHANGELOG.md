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
- `package.json` with project metadata. It is the single source of truth for the version number. QuickQuit is not published on npm.
- Contributor documentation: contribution guide with an AI usage policy, Contributor Covenant code of conduct, security policy, support guide, and issue and pull request templates.

### Changed

- The app is compiled with an explicit macOS 13.0 deployment target, so the binary matches the minimum version declared in `Info.plist`.
- The app version is now the three-part semantic version `1.0.0` (previously `1.0`).
- `build.sh` stops with a clear message when it is run on a system other than macOS or when the Swift compiler is missing.
- When reinstalling, the installer waits for launchd to finish unloading the previous LaunchAgent before loading the new one, to avoid a possible failure if the two steps overlap.

[Unreleased]: https://github.com/choudharyjayesh668/QuickQuit/commits/main
