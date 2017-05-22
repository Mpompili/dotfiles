#!/bin/bash

set -eu
set -o pipefail

# http://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
pushd "$(dirname $0)" > /dev/null
THISDIR="$(pwd -P)"

RESET="\e[49m"
BLUE_BG="\e[44m"
GREEN_BG="\e[100m"

for file in .* ; do
  if [[ "${file}"  = ".git"  || \
        "${file}" == "." || \
        "${file}" == ".." || \
        "${file}" == ".gitignore" || \
        "${file}" == ".gitmodules" \
     ]]; then
    continue
  fi

  # TODO handle conflicts
  source="${THISDIR}/${file}"
  dest="$HOME/${file}"
  if [[ -e "${dest}"  || -h "${dest}" ]]; then
    if [[ $(readlink "${dest}") == "${source}" ]] ; then
      echo -e "Skipping\t${BLUE_BG}${source}${RESET}\t->\t${GREEN_BG}${dest}${RESET}"
      continue
    fi
    diff "${dest}" "${source}" || true
    echo "${dest} already exists and is not a symlink. Overwrite it? y/N"
    read answer
    answer="${answer:-N}"
    if [[ "${answer}" == "y" ]]  ; then
      backup="${dest}.bak"
      echo "Overwriting previous file. Saved to ${backup}"
      mv "${dest}" "${backup}"
      ln -sf "${source}" "${dest}"
    fi
  else
    echo -e "Linking\t${GREEN_BG}${source}${RESET}\t->\t${BLUE_BG}${dest}${RESET}"
    ln -s "${source}" "${dest}"
  fi
done

mkdir -p "${HOME}/bin"
mkdir -p "${HOME}/src/go"

mkdir -p "${HOME}/.config"
ln -sf "${HOME}/.vim" "${HOME}/.config/nvim"

if command -v i3 > /dev/null ; then
  ln -sf "${THISDIR}/linux/.i3" "${HOME}/.config/i3"
fi

for file in "${THISDIR}/bin/*" ; do
  ln -sf $file "${HOME}/bin/"
done

# TODO OS-XX specific hooks
if command -v defaults > /dev/null ; then
  # do stuff from here: https://github.com/herrbischoff/awesome-osx-command-line
  # remove some siulator crap
  xcrun simctl delete unavailable

  # add a stack of recent apps!!
  defaults write com.apple.dock persistent-others -array-add '{ "tile-data" = { "list-type" = 1; }; "tile-type" = "recents-tile"; }' && \
    killall Dock

  # enable quit finder
  defaults write com.apple.finder QuitMenuItem -bool true && \
    killall Finder
fi
popd > /dev/null
