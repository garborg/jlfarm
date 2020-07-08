#!/usr/bin/env bash

#
# Install and manage versions of Julia
#

set -euo pipefail

# Terminology -
#
# name: julia julia-1 julia-1.3-pre julia-nightly
# version: "" 1.0 1.2.3 1.2.3-alpha 1.2-pre d762e8c235 nightly
# install_version: 1.2.3 1.2.3-alpha nightly
# tags: 1.2.3 1.2.3-alpha d762e8c235

# Current Julia LTS version
LTS_MINOR=1.0

# is_prerelease "$tag"
is_prerelease () {
  [[ "$1" =~ ^[[:digit:]]\.[[:digit:]]\.[[:digit:]]-[[:alnum:]]+$ ]]
}

# is_lts "$tag"
is_lts () {
  [[ "$1" == "$LTS_MINOR"* ]]
}

# version_from_name julia
# version_from_name julia-1.2.3
version_from_name () {
  if [[ "$1" == "julia" ]]; then
    echo ""
  else
    echo "${1:6}"
  fi
}

# extract_tag "$target"
extract_tag () {
  if [[ "$(basename "$(dirname "$1")")" != "bin" ]]; then
    return 1
  fi
  version_from_name "$(basename "$(dirname "$(dirname "$1")")")"
}

# linked_path "$link"
linked_path () {
  if [[ -h "$1" ]] && [[ -e "$1" ]]; then
    readlink -f "$1"
  else
    echo ""
  fi
}

# linked_tag "$link"
linked_tag () {
  if [[ -h "$1" ]] && [[ -e "$1" ]]; then
    extract_tag "$(readlink -f "$1")"
  else
    echo ""
  fi
}

# older_than "$new_tag" "$base_tag"
older_than () {
  if [[ "$1" != "$2" ]]; then
    patch2=${2:0:5}
    # pre-release to release
    [[ "$1" == "$patch2" ]] && return 1
    patch1=${1:0:5}
    # release to pre-release
    [[ "$patch1" == "$2" ]] && return 0
  fi
  [[ "$1" < "$2" ]]
}

# replace_link "$target" "$link"
replace_link () {
  link=$2
  rm -f "$link"
  ln -s "$1" "$link"

  # Warn if link is obscuring something more current
  name=$(basename "$link")
  tag=""
  for path in $(which -a "$name"); do
    if [[ "$tag" == "" ]]; then
      if [[ "$path" == "$link" ]]; then
        tag=$(linked_tag "$path")
      fi
    else
      following_tag=$(linked_tag "$path")
      if older_than "$tag" "$following_tag"; then
        echo "Linked to '$tag' at '$link', but it's obscuring '$following_tag' at '$path'"
      fi
    fi
  done
}

# replace_link_if_not_older "$target" "$link"
replace_link_if_not_older () {
  target_tag=$(extract_tag "$1")
  link_tag=$(linked_tag "$2")
  respect_lts=${3:-}
  if older_than "$target_tag" "$link_tag"; then
    echo "Leaving '$2' pointing at '$link_tag' rather than replacing with older version '$target_tag'."
  elif [[ -n "$respect_lts" ]] && is_lts "$link_tag" && ! is_lts "$target_tag"; then
    echo "Leaving '$2' pointing LTS version ('$link_tag') rather than replacing with non-LTS version ('$target_tag')."
  else
    replace_link "$@"
  fi
}

get_dir () {
  if [[ "$(whoami)" == "root" ]]; then
    echo "${JULIA_DOWNLOAD:-"/opt/julias"}"
  else
    echo "${JULIA_DOWNLOAD:-"$HOME/.local/opt/julias"}"
  fi
}

get_linkdir () {
  if [[ "$(whoami)" == "root" ]]; then
    echo "${JULIA_INSTALL:-"/usr/local/bin"}"
  else
    echo "${JULIA_INSTALL:-"$HOME/.local/bin"}"
  fi
}

# add_one "$install_version"
add_one () {
  version=$1
  make_default=$2
  force=$3

  dir=$(get_dir)
  linkdir=$(get_linkdir)
  mkdir -p "$dir" || return 1
  mkdir -p "$linkdir" || return 1

  if [[ "$version" == "nightly" ]]; then
    url="https://julialangnightlies-s3.julialang.org/bin/linux/x64/julia-latest-linux64.tar.gz"
    if ! (curl -fL "$url" | tar -xz -C "$dir"); then
      echo "^^Failed to find, download, or extract binary for '$version'"
      return 1
    fi
    name=$(ls -t1 "$dir" | head -n1)
    bin="$dir/$name/bin/julia"
    if [[ -e "$bin" ]]; then
        replace_link "$bin" "$linkdir/julia-nightly"
    else
        echo "Failure to extract nightly tag '$bin'"
        return 1
    fi
  else
    patch=${version:0:5}
    minor=${version:0:3}
    major=${version:0:1}

    url="https://julialang-s3.julialang.org/bin/linux/x64/$minor/julia-${version}-linux-x86_64.tar.gz"
    tag_dir="$dir/julia-$version"
    if [[ -d "$tag_dir" ]] && ! $force; then
      echo "'$tag_dir' already exists, skipping download"
    elif ! (curl -fL "$url" | tar -xz -C "$dir"); then
      echo "^^Failed to find, download, or extract binary for '$version'"
      return 1
    fi

    bin="$tag_dir/bin/julia"
    if is_prerelease "$version"; then
      end="-pre"
      replace_link_if_not_older "$bin" "$linkdir/julia-$minor$end"
    else
      end=""
      replace_link_if_not_older "$bin" "$linkdir/julia-$patch$end"
      replace_link_if_not_older "$bin" "$linkdir/julia-$minor$end"
      replace_link_if_not_older "$bin" "$linkdir/julia-$major$end"
    fi

    if [[ "$make_default" == "yes" ]]; then
      replace_link "$bin" "$linkdir/julia$end"
    elif [[ "$make_default" == "auto" ]]; then
      replace_link_if_not_older "$bin" "$linkdir/julia$end" "yes"
    fi
  fi
}

# currently, tags and 'nightly' are supported versions
jlfarm_add () {
  declare -a install_versions

  # whether or not plain `julia` should point here
  make_default="auto"
  # whether or not to install over existing directory
  force=false
  for arg in "$@"; do
    if [[ "$arg" == "--default" ]]; then
      make_default="yes"
    elif [[ "$arg" == "--no-default" ]]; then
      make_default="no"
    elif [[ "$arg" == "--force" ]] || [[ "$arg" == "-f" ]]; then
      force=true
    else
      install_versions+=("$arg")
    fi
  done

  for install_version in "${install_versions[@]}"; do
    add_one "$install_version" "$make_default" $force
  done
}

remove_one () {
  tag=$1

  dir=$(get_dir)
  linkdir=$(get_linkdir)

  tag_dir="$dir/julia-$tag"
  if ! rm -rf "$tag_dir"; then
    echo "Failed to remove '$tag_dir'"
    return 1
  fi

  # Remove/replace any links that point directly to tag_dir
  all_ts=$(all_dir_tags "$dir")
  for link in "$linkdir/julia"*; do
    if test -h "$link" && [[ "$(readlink "$link")" == "$tag_dir"* ]]; then
      link_version=$(version_from_name "$(basename "$link")")
      latest_match=$(latest_matching_tag "$link_version" "$all_ts")
      if [[ -z "$latest_match" ]]; then
        rm "$link"
      else
        bin="$dir/julia-$latest_match/bin/julia"
        replace_link "$bin" "$link"
      fi
    fi
  done
}

jlfarm_remove () {
  for tag in "$@"; do
    remove_one "$tag"
  done
}

latest_matching_tag () {
  version=$1
  latest_match=""

  for tag in "${@:2}"; do
    if [[ "$version" == *"pre" ]]; then
      if [[ "$version" == "pre" ]]; then
        numeric=""
      else
        let len=${#version}-4
        numeric=${version:0:len}
      fi
      if [[ "$tag" == "$numeric"*"-"* ]] && [[ "$tag" > "$latest_match" ]]; then
        latest_match=$tag
      fi
    elif [[ ${#tag} = 5 ]]; then
      if [[ "$tag" == "$version"* ]] && [[ "$tag" > "$latest_match" ]]; then
        latest_match=$tag
      fi
    fi
  done
  echo "$latest_match"
}

all_tags () {
  declare -a seen

  names=$(compgen -c | grep -E "^julia(-|$)" | sort | uniq)
  for name in $names; do
    for path in $(which -a "$name"); do
      t=$(linked_tag "$path")
      if [[ ! "${seen[*]}" =~ (^| )${t}( |$) ]]; then
        echo "$t"
        seen+=($t)
      fi
    done
  done
}

all_dir_tags () {
  dir=$1
  for path in "$dir/julia-"*; do
    version_from_name "$(basename "$path")"
  done
}

latest_pre_tag() {
  latest=""
  for tag in "$@"; do
    if [[ "$tag" == *-* ]] && [[ "$tag" > "$latest" ]]; then
      latest=$tag
    fi
  done
  echo "$latest"
}

# is_superceded "$tag" "$all_possible_tags"
is_superceded () {
  # Currently handles non-nightly tags
  tag=$1
  shift

  latest_release=$(latest_matching_tag "" "$@")
  latest_lts=$(latest_matching_tag "$LTS_MINOR" "$@")
  latest_pre=$(latest_pre_tag "$@")

  if [[ "$tag" == "$latest_release" ]]; then
    return 1
  elif [[ "$tag" == "$latest_lts" ]]; then
    return 1
  elif [[ "$tag" == "$latest_pre" ]]; then
    return 1
  fi
}

jlfarm_status () {
  verbose=false
  for arg in "$@"; do
    if [[ "$arg" == "--verbose" ]] || [[ "$arg" == "-v" ]]; then
      verbose=true
    else
      echo "Unsupported flag '$arg'"
      return 1
    fi
  done

  linkdir=$(get_linkdir)
  broken_links=$(find "$linkdir" -iname "julia*" -type l ! -exec test -e {} \; -print)
  if [[ -n "$broken_links" ]]; then
      printf "Broken links in '%s':\n%s\n\n" "$linkdir" "$broken_links"
  fi

  all_ts=$(all_tags)

  # Tracking which versions in dir are on path
  dir=$(get_dir)
  dir_linked_tags=()

  # For every julia command on path
  echo "On path:"
  names=$(compgen -c | grep -E "^julia(-|$)" | sort | uniq)
  for name in $names; do
    v=$(version_from_name "$name")
    latest_match=$(latest_matching_tag "$v" $all_ts)

    # For each match (ordered from highest to lowest priority)
    paths=$(which -a "$name")
    for path in $paths; do
      tag=$(linked_tag "$path")
      if [[ "$(linked_path "$path")" == "$dir"* ]]; then
        dir_linked_tags+=("$tag")
      fi
      # Show whether or not outdated
      if [[ "$v" == "nightly" ]]; then
        info="  * ?"
      elif [[ -z "$tag" ]]; then
        info="  * UNKNOWN_TARGET"
      elif older_than "$tag" "$latest_match"; then
        info="  * NEWER_MATCH: $latest_match"
      elif is_superceded "$tag" $all_ts; then
        info=" * OLD"
      else
        info=""
      fi
      target=$tag
      if $verbose; then
        target=$(readlink -f "$path")
      fi
      # Along with basic stats
      echo "$name @ $path -> $target$info"
    done
  done

  unlinked_tags=()
  for tag in $(all_dir_tags "$dir"); do
    if ! [[ " ${dir_linked_tags[*]} " =~ " $tag " ]]; then
      unlinked_tags+=("$tag")
    fi
  done
  if [[ ${#unlinked_tags[@]} -ne 0 ]]; then
    printf "\nIn '%s' but not on linked anywhere on path:\n" "$dir"
    echo "${unlinked_tags[*]}"
  fi
}

# Script entry point

command=$1

valid_commands="'add', 'remove', 'status'"
if [[ "$command" =~ ^[a-z]+$ ]] && [[ "$valid_commands" == *"'$command'"* ]]; then
  "jlfarm_$command" "${@:2}"
else
  echo "Invalid command '$command', supported commands: $valid_commands"
  exit 1
fi
