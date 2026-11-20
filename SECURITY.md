# Security Policy

## Supported versions

Security fixes are made against the latest code on the `main` branch. There are no separately maintained older versions.

## Reporting a vulnerability

Please do not report security problems in public issues, pull requests, or discussions.

Report them privately with GitHub's private vulnerability reporting:

1. Open the [Security tab](https://github.com/choudharyjayesh668/QuickQuit/security) of this repository.
2. Click **Report a vulnerability**, or go straight to the [report form](https://github.com/choudharyjayesh668/QuickQuit/security/advisories/new).
3. Fill in the form and submit it. Only you and the maintainer can see the report.

You need a GitHub account to submit a report.

## What to include

- A description of the problem and its impact.
- The QuickQuit version or commit hash. To read the version of an installed copy, run `defaults read /Applications/QuickQuit.app/Contents/Info CFBundleShortVersionString`.
- Your macOS version and whether the Mac is Apple silicon or Intel.
- Step-by-step instructions to reproduce the problem.
- A proof of concept, logs, or screenshots, if you have them.
- A suggested fix, if you have one.

Remove passwords and personal data from anything you attach.

## What to expect

- This project is maintained by one volunteer. The maintainer will acknowledge your report as soon as practical.
- The maintainer will investigate, keep you informed through the private report, and work with you on a fix.
- Once a fix is available, the advisory will be published and you will be credited unless you ask not to be.

## Responsible disclosure

- Give the maintainer a reasonable amount of time to fix the problem before you disclose it publicly.
- Do not access, change, or delete other people's data while researching.
- Test only on systems you own or have permission to use.

## Scope

In scope: the Swift source in `Sources/`, the build, install, and uninstall scripts, the `quickquit` command and the npm `postinstall` step, and the GitHub Actions workflow in this repository.

Known characteristics that are not vulnerabilities:

- QuickQuit is ad-hoc signed and is not Developer ID signed or notarized. This is documented in the [README](README.md#security-and-privacy).
- The npm package runs a `postinstall` script that builds and installs the app on a global install. This is documented in the [README](README.md#what-installation-does) and can be turned off with `--ignore-scripts` or `QUICKQUIT_SKIP_POSTINSTALL=1`.
- Any app running under the same user account can register the same keyboard shortcut first, or send quit requests to other apps. That is standard macOS behavior.
