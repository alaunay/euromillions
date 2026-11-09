# Changelog

Generated from the git history by `tools/changelog.py`; run it for a tag to
write the release notes.

## v0.0.1 - 2026-11-09

### Changes

- Take the version from the tag (#15)
- Publish the packages on a tag (#14)
- Name the demo colours in the spec (#13)
- Feed code scanning from shellcheck (#12)
- Declare the supported systems (#11)
- Build for CentOS and check BSD and macOS (#10)
- Package for Debian and Fedora (#9)
- Cover the shell scripts with bats (#8)
- Use the installed generator (#7)
- Drive the demo from a spec file (#6)
- Move the demo generator to its own repository (#5)
- Check the python generator (#4)
- Give the README more air (#3)
- Document the pull request flow (#2)
- Make shellcheck a required test dependency
- Document the PO workflow in the README
- Expect the warning in the unknown-language case
- Warn when a language has no catalogue
- Translate with GNU gettext
- Read the grid shape from the environment
- List the help option in the usage line
- Translate the help and the argument errors
- Name the palette colours in the source
- Lint the scripts with shellcheck
- Colour the output with the EuroMillions palette
- Animate the demo as SVG instead of GIF
- Replace the static capture with an animated demo
- Rework the README with a terminal capture
- Fix the README gaps
- Add multilingual output with a French translation
- Silence the checkout deprecation warning
- Run the bats suite in CI
- Add bats tests for the draw
- Document the commit email requirement
- Enforce the trailer rules with a commit-msg hook
- Add AGENTS.md with repository rules
- Make the draw failure-proof
- Revert "Add https://www.code-inspector.com/ results" This reverts commit 05f7276f50b84f5ced7eab1ef86b7e70e0002aaf. Does not exist anymore (and was not useful anyway)
- Use a better random source
- Add https://www.code-inspector.com/ results
- #CI: Prefer mapfile or read -a to split command output (or quote to avoid splitting).
- Argument mixes string and array. Use * or separate argument.
- I waited to be 40 to discover shuf from coreutils
- Use $((..)) instead of deprecated $[..]
- $/${} is unnecessary on arithmetic variables.
- Instead of 'let expr', prefer (( expr )) .
- $/${} is unnecessary on arithmetic variables.
- STARS variable isn't used
- drop debug
- compare strings
- add sorting and a bit of uniqueness
- Use a few variables
- Force bash
- 12 stars in 2016
- Reflect ameliorations, specify that I'm no diviner
- Stars sorting
- Get different stars
- Use functions
- Add a bit of doc
- Get 5 random numbers and 2 stars
- Initial commit
