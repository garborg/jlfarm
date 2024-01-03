# DEPRECATED: This predated [JuliaLang/juliaup](https://github.com/JuliaLang/juliaup), which you should use instead.

# jlfarm

Install, organize, review, and remove versions of the Julia programming language.

## Scope (current, plus potential todos)

- [x] x86 linux support
- [ ] mac support
- [ ] other \*nix support
- [x] `add` (download, install, and link) current and historical release, prerelease, and nightly versions of Julia
- [x] `remove` (delete and remove/replace links) installed versions of Julia
- [x] check `status` of all versions of Julia on PATH
- [x] verify gpg signatures of downloads before installing
- [ ] support specifying 'latest' in place of precise release or pre-release versions
- [ ] evaluate version freshness based on what's released rather than what's on computer
    - probably not going to bother until [JuliaLang#33817](https://github.com/JuliaLang/julia/issues/33817) makes the operation cheap
- [ ] recognize and play nicely with source builds

## Usage

Ways to invoke:

```bash
# Directly from github without jlfarm saved anywhere
bash -c "$(curl -fsSL https://raw.githubusercontent.com/garborg/jlfarm/master/jlfarm.bash)" add 1.4.2

# From the file locally
./jlfarm.bash add 1.4.2

# If added to PATH as `jlfarm`
jlfarm add 1.4.2
```

Adding versions of julia:

```bash
jlfarm add 1.4.1
jlfarm add 1.4.1 1.5.0-rc1

# Force `julia` to point at LTS despite currently pointing to a newer version
jlfarm add --default 1.0.5

# Force `julia` to point at 1.4.1 despite currently pointing at LTS branch
# (doesn't re-download by default)
jlfarm add --default 1.4.1

# You could force it to re-download
jlfarm add --force 1.4.1
jlfarm add -f 1.4.1

# If for some reason you want to skip gpg signature verification
jlfarm add --no-verify 1.3.0

# Leave `julia` pointing at 1.4.1 even though 1.4.2 is newer
jlfarm add --no-default 1.4.2

# Update `julia` to point to 1.4.2 after all
jlfarm add 1.4.2

# Just for good measure (used below)
jlfarm add 1.5.0-beta1
```

Removing versions of julia:

```bash
# Removes julia-1.0* & julia-1.4.2 links,
# points julia, julia-1 & julia-1.4 links at 1.4.1, and
# points julia-pre & julia-1.5-pre links at 1.5.0-beta1
jlfarm remove 1.0.5 1.4.2 1.5.0-rc1
```

Overriding install locations:

```bash

# By default,
# binaries go (and are looked for) in "$HOME/.local/opt/julias", and
# links go (and are looked for) in "$HOME/.local/bin".
jlfarm add 1.1.0 1.1.1
jlfarm remove julia 1.1.0 1.1.1

# If run by root,
# binaries go (and are looked for) in "/opt/julias", and
# links go (and are looked for) in "/usr/local/bin".
sudo jlfarm add 1.1.0 1.1.1

# Locations are customizable.
sudo JULIA_DOWNLOAD=/opt JULIA_INSTALL=/usr/local/bin jlfarm add 1.1.1
sudo JULIA_DOWNLOAD=/opt JULIA_INSTALL=/usr/local/bin jlfarm remove 1.1.1

# This time linking will warn that e.g. julia-1.1 is shadowing a
# more-current link in /usr/local/bin
jlfarm add 1.1.0
```

Status:

```bash
# See what julia versions are installed where on path,
# which are clearly outdated,
# and if there are any broken links in `JULIA_INSTALL`,
# or unlinked versions in `JULIA_DOWNLOAD`.
jlfarm status
sudo jlfarm status

# Show full target paths
jlfarm status -v
```

## Alternatives

[JILL](https://github.com/abelsiqueira/jill) - bash script to install release or prerelease versions on mac and linux

[jill.py](https://github.com/johnnychen94/jill.py) - python package to install julia versions cross-platform

## Motivation and Design

I tried to integrate the options listed above (under 'Alternatives') into my workflow, but neither hit on all these expectations and features:

- Installing nightlies
- Verifying integrity of signed binaries
- Installing old versions shouldn't by default silently overwrite links pointing to newer versions
- Any automatic linking should warn of potentially undesirable behavior, like:
  - Hiding newer version elsewhere on path
  - Flipping between an LTS version and a newer version
- When intalling '[major].[minor]-latest':
  - Precise installed versions should be obvious when glancing at install dir or symlinks (e.g. is '1.2-latest' actually '1.2.0' or '1.2.3'?)
  - Having installed '1.2-latest' during '1.2.0' times shouldn't block '1.2-latest' from installing the current latest version, e.g. during '1.2.1' times
- Removing previously installed versions
- Help seeing what you might want to remove

I'd be happy for any of these features to make it into `jill` or `jill.py` -- hopefully the implementation here aids in evaluating these features' desirability, design space, and maintence burden.

The last time I did involved shell scripting, I aimed for posix compatibility -- I'm sure glad to be using bash here, but there's enough logic (more than I was planning) that it'd be nice to be using a 'real' programming language. I'd be more likely to provide simplified update/maintenance functionality in a language with nice data structures.

## Contributing

As you can see, I've stopped at the basics for now.

I'm happy to entertain PRs. For PRs that aren't straightforward completions of an empty checkbox in the 'Scope' section, no guarantees, so probably best to open an issue to kick off a discussion first if you're worried about risking lost time.

I am also more likely to chip away at missing functionality if there are users clammoring for it, so if you try it, let me know!
