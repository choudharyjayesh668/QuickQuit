# Contributing to QuickQuit

Thank you for your interest in QuickQuit. Contributions of every size are welcome: bug reports, ideas, documentation fixes, tests, and code. You do not need to be an experienced macOS developer to help.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Contents

- [Ways to contribute](#ways-to-contribute)
- [Reporting bugs](#reporting-bugs)
- [Requesting features](#requesting-features)
- [Development environment](#development-environment)
- [Contribution workflow](#contribution-workflow)
- [Branch naming](#branch-naming)
- [Commit messages](#commit-messages)
- [Coding standards](#coding-standards)
- [Testing requirements](#testing-requirements)
- [Submitting a pull request](#submitting-a-pull-request)
- [Code review and approval](#code-review-and-approval)
- [AI usage policy](#ai-usage-policy)
- [Versioning and releases](#versioning-and-releases)
- [License](#license)

## Ways to contribute

- Report a bug or suggest a feature.
- Improve the documentation.
- Add or improve tests.
- Fix an open [issue](https://github.com/choudharyjayesh668/QuickQuit/issues). Issues labelled `good first issue` are a good place to start.

For a large change or a change in behavior, please open an issue first so the approach can be agreed before you spend time on it. Small fixes can go straight to a pull request.

## Reporting bugs

1. Search the [existing issues](https://github.com/choudharyjayesh668/QuickQuit/issues) to see whether it is already reported.
2. Open a [bug report](https://github.com/choudharyjayesh668/QuickQuit/issues/new?template=bug_report.yml) and fill in the form.
3. Leave out passwords, personal documents, and other private data.

Security problems must not be reported in public issues. Follow [SECURITY.md](SECURITY.md) instead.

## Requesting features

Open a [feature request](https://github.com/choudharyjayesh668/QuickQuit/issues/new?template=feature_request.yml). Describe the problem you want solved, not only the solution you have in mind. QuickQuit is deliberately small, so requests that keep it small and safe are the most likely to be accepted.

## Development environment

You need:

- macOS 13 or newer
- Apple Command Line Tools with a Swift 6 compiler (`xcode-select --install`). Full Xcode is not required.
- Git

There are no third-party dependencies and nothing to install with a package manager.

Check your tools:

```sh
swift --version
xcode-select -p
```

Build and test:

```sh
./build.sh    # creates build/QuickQuit.app
./test.sh     # compiles and runs the unit tests
```

If you have Node.js installed, `npm run build` and `npm test` run the same two scripts. Node.js is optional.

To try your build without installing it:

```sh
open build/QuickQuit.app
```

Only one copy of QuickQuit runs at a time. If you have an installed copy, a second copy exits immediately, so remove the installed one first with `./Uninstall\ QuickQuit.command`.

> **Warning:** Control+Shift+Q asks every open Dock app to quit, including your editor and Terminal. Save your work before testing the shortcut by hand.

## Contribution workflow

1. **Fork** the repository: click **Fork** at the top right of the [repository page](https://github.com/choudharyjayesh668/QuickQuit).

2. **Clone** your fork and add the original repository as `upstream`:

   ```sh
   git clone https://github.com/YOUR-USERNAME/QuickQuit.git
   cd QuickQuit
   git remote add upstream https://github.com/choudharyjayesh668/QuickQuit.git
   ```

3. **Create a branch** from an up-to-date `main`:

   ```sh
   git fetch upstream
   git switch -c fix/short-description upstream/main
   ```

4. **Make your change.** Keep it focused on one thing.

5. **Build and test:**

   ```sh
   ./build.sh
   ./test.sh
   ```

6. **Update the documentation** if behavior, installation, or usage changed, and add a line to the `Unreleased` section of [CHANGELOG.md](CHANGELOG.md) for anything users will notice.

7. **Commit** with a clear message (see [Commit messages](#commit-messages)):

   ```sh
   git add <files>
   git commit -m "fix: describe the change"
   ```

8. **Push** the branch to your fork:

   ```sh
   git push origin fix/short-description
   ```

9. **Open a pull request** against `main` and fill in the template.

10. **Respond to review.** Push further commits to the same branch; the pull request updates automatically.

## Branch naming

Use a short prefix and a few words in lowercase, separated by hyphens:

| Prefix | Use for | Example |
| --- | --- | --- |
| `feat/` | New features | `feat/custom-exclusion-list` |
| `fix/` | Bug fixes | `fix/installer-reinstall-race` |
| `docs/` | Documentation only | `docs/clarify-uninstall` |
| `test/` | Tests only | `test/quit-policy-cases` |
| `chore/` | Maintenance, CI, tooling | `chore/update-ci-runner` |

## Commit messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) style:

```text
<type>: <short summary in the imperative mood>

<optional body explaining what changed and why>
```

Common types are `feat`, `fix`, `docs`, `test`, `refactor`, and `chore`. For example:

```text
fix: wait for launchd to unload the agent before reinstalling
```

Keep the summary under about 72 characters. Reference related issues in the body, for example `Fixes #12`.

## Coding standards

Project principles:

- Keep QuickQuit small and native to macOS.
- Ask apps to quit normally. Never force-quit them.
- Keep Finder and essential system processes excluded.
- Preserve the LaunchAgent's start-at-login and relaunch behavior, and avoid repeated alerts or restart loops.
- Do not add dependencies unless they solve a clear need that has been discussed in an issue.
- Do not add network access, analytics, or new permission requirements without prior discussion.

Swift:

- The code is built in Swift 6 language mode and must compile without warnings. CI builds with `-warnings-as-errors`.
- Indent with 4 spaces and follow the style of the surrounding code.
- Keep logic that can be tested without side effects (such as the rules in `Sources/QuitPolicy.swift`) separate from AppKit and launchd code.
- Use only APIs available on macOS 13. The build's deployment target enforces this.

Shell scripts:

- Use `bash` with `set -euo pipefail` where a failure should stop the script.
- Quote variables and paths. File names in this project contain spaces.
- Scripts must pass [ShellCheck](https://www.shellcheck.net/). CI runs it; to run it locally, install it (for example with `brew install shellcheck`) and run:

  ```sh
  shellcheck build.sh test.sh "Install QuickQuit.command" "Uninstall QuickQuit.command"
  ```

The [.editorconfig](.editorconfig) file sets indentation and line endings for editors that support it. The project has no automatic code formatter.

## Testing requirements

- `./build.sh` and `./test.sh` must both succeed before you open a pull request.
- Add or update unit tests in `Tests/main.swift` when you change which apps are asked to quit.
- The unit tests cover the quit policy only. The global shortcut, the installer, the uninstaller, and the LaunchAgent have no automated tests, so if you change them, test them by hand and describe what you did in the pull request.
- Never test the shortcut while unsaved work is open.

CI runs on every pull request. It lints the shell scripts, runs the unit tests, builds the app with warnings treated as errors, and verifies the app bundle on macOS 15 (Apple silicon and Intel) and macOS 26.

## Submitting a pull request

- Fill in every section of the [pull request template](.github/PULL_REQUEST_TEMPLATE.md).
- Link the related issue with `Fixes #123` or `Refs #123`.
- Keep the pull request focused. Unrelated changes belong in separate pull requests.
- State the macOS and Swift versions you tested with.
- Do not commit the `build/` folder, app bundles, signing identities, certificates, personal data, or secrets.
- Complete the AI usage disclosure.

## Code review and approval

- The maintainer, [@choudharyjayesh668](https://github.com/choudharyjayesh668), reviews every pull request.
- A pull request needs the maintainer's approval and passing CI checks before it is merged. Only the maintainer merges.
- Review looks at correctness, safety (no force-quitting, system apps excluded), simplicity, tests, and documentation.
- You may be asked for changes. That is a normal part of review, not a rejection.
- This is a volunteer-maintained project, so reviews can take some time. If a pull request has had no response after two weeks, a polite comment on it is welcome.

## AI usage policy

You may use AI tools (for example ChatGPT, Claude, GitHub Copilot, or Cursor) to help with a contribution. Using AI does not disqualify a contribution, and contributions are judged on their quality, not on how they were produced.

Every pull request must include an AI usage disclosure. The pull request template has a section for it. State:

1. **Whether AI tools were used.** "No AI tools were used" is a complete answer.
2. **Which tools**, if any.
3. **Which parts** of the contribution were AI-assisted: code, tests, documentation, commit messages, or the pull request text.
4. **That you reviewed, tested, and verified** the AI-assisted parts yourself.

You remain fully responsible for everything you submit, whether or not AI helped produce it. That includes:

- **Correctness:** you understand the change and can explain it during review.
- **Security:** the change introduces no vulnerabilities, secrets, or unsafe behavior.
- **Licensing:** you have the right to submit the content under the MIT License, and it does not copy code that is incompatible with that license.
- **Compliance:** the change follows this guide and the Code of Conduct.

Pull requests with untested or unreviewed AI output, or with an inaccurate disclosure, may be closed. Disclosure is not needed for trivial editor assistance such as spell checking or single-line autocomplete.

The same policy applies to issues: if an AI tool wrote a bug report or feature request for you, check that it is accurate before posting it.

The project's own AI usage is disclosed in the [README](README.md#ai-usage-disclosure) and in [CREDITS.md](CREDITS.md).

## Versioning and releases

QuickQuit follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- The version number lives in the `version` field of [package.json](package.json). `build.sh` reads it and writes it into the app's `Info.plist`.
- Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md).
- Contributors should not change the version number. The maintainer does that when preparing a release.

Release steps for the maintainer:

1. Update `version` in `package.json` and move the `Unreleased` entries in `CHANGELOG.md` under the new version and date.
2. Build on a supported Mac, then test installation, start at login, relaunch, shortcut registration, and uninstallation with all important work saved.
3. Commit, tag the commit `vMAJOR.MINOR.PATCH`, and push the tag.
4. Publish a GitHub release with notes that state the supported macOS versions and known limitations.

QuickQuit is not published on npm, and `package.json` is marked `private` so it cannot be published by accident. Builds are ad-hoc signed and must not be described as notarized or Apple-approved.

## License

By contributing, you agree that your contribution is provided under the project's [MIT License](LICENSE). You keep the copyright in your contribution.
