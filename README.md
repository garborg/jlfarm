# JLFARM

Install and manage versions of Julia

## Scope (current, plus potential todos)

- [x] x86 linux support
- [ ] mac support
- [ ] other \*nix support
- [x] `add` (download, install, and link) current and historical release, prerelease, and nightly versions of Julia
- [x] `remove` (delete and remove/replace links) installed versions of Julia
- [x] check `status` of all versions of Julia on PATH
- [ ] support specifying 'latest' in place of precise release or pre-release versions
- [ ] evaluate version freshness based on what's released rather than what's on computer
    - probably not going to bother until [JuliaLang#33817](https://github.com/JuliaLang/julia/issues/33817) makes the operation cheap
- [ ] verify gpg signatures of downloads before installing
- [ ] recognize and play nicely with source builds

## Alternatives

[JILL](https://github.com/abelsiqueira/jill) - bash script to install release or prerelease versions on mac and linux

[jill.py](https://github.com/johnnychen94/jill.py) - python package to install julia versions cross-platform

## Motivation and Design

I tried replacing an outdated, adhoc install script with the options listed above, but each missed on some of the following features and expectations:

- Installing nightlies
- Installing an old version shouldn't default to silently overwrite links pointing to newer versions
- Any automatic linking should warn of any potentially undesirable behavior
  - Hiding newer version elsewhere on path
  - Flipping between LTS version and newer version
- When intalling '[major].[minor]-latest':
  - Precise installed versions should be clear from looking at install dir or symlinks (e.g. is '1.2-latest' actually '1.2.0' or '1.2.3'?)
  - Installing '1.2-latest' in '1.2.0' times shouldn't block '1.2-latest' from installing '1.2.[patch]' down the road
- Removing previously installed versions
- Help seeing what you might want to remove

I'd be happy for any of these features to make it into `jill` or `jill.py` -- hopefully the implementation here is a vehicle for evaluating these features' desirability, design space, and maintence burden.

The last time I did any involved shell scripting, I aimed for posix compatibility -- I'm sure glad to be using bash here, but there's enough logic (more than I was planning) that it'd be nice to be using a 'real' programming language. I'd be more likely to provide simplified update/maintenance funtionality in a language with nice data structures.

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
# Leave `julia` pointing at 1.4.1 even though 1.4.2 is newer
jlfarm add --no-default 1.4.2
# Update that link after all
jlfarm add 1.4.2
# Just for good measure
jlfarm add 1.5.0-beta1
```

Removing versions of julia:

```bash
# Removes julia-1.0* & julia-1.4.2 links,
# points julia, julia-1 & julia-1.4 links at 1.4.2, and
# points julia-pre & julia1.5-pre links at 1.5.0-beta1
jlfarm remove 1.0.5 1.4.2 1.5.0-rc1
```

Controlling paths:

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
# and if there are any broken links in `JULIA_INSTALL`.
jlfarm status
sudo jlfarm status
# Show full target paths
jlfarm status -v
```

## Contributing

As you can see, I've stopped at the basics for now.

I'm happy to entertain PRs. For PRs that aren't straightforward completions of an empty checkbox in the 'Scope' section, no guarantees, so probably best to open an issue to kick off a discussion first if you're worried about risking lost time.

I am also more likely to chip away at missing functionality if there are users clammoring for it, so if you try it, let me know!
