#!/bin/bash -e
set -e
has() {
  type "$1" > /dev/null 2>&1
  return $?
}

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee /tmp/installlog.txt)

# Without this, only stdout would be captured - i.e. your
# log file would not contain any error messages.
exec 2>&1

if has "wget"; then
  DOWNLOAD="wget --no-check-certificate -nc"
elif has "curl"; then
  DOWNLOAD="curl -sSOL"
else
  echo "Error: you need curl or wget to proceed" >&2;
  exit 1
fi

VERSION=1
NODE_VERSION=v0.13.0
C9_DIR=$HOME/.c9
NPM=npm
NODE=node

export TMP=$C9_DIR/tmp
export TMPDIR=$TMP

PYTHON=python

start() {
  if [ $# -lt 1 ]; then
    start base
    return
  fi
  
  # Try to figure out the os and arch for binary fetching
  local uname="$(uname -a)"
  local os=
  local arch="$(uname -m)"
  case "$uname" in
    Linux\ *) os=linux ;;
    Darwin\ *) os=darwin ;;
    SunOS\ *) os=sunos ;;
    FreeBSD\ *) os=freebsd ;;
  esac
  case "$uname" in
    *x86_64*) arch=x64 ;;
    *i*86*) arch=x86 ;;
    *armv6l*) arch=arm-pi ;;
    *armv7l*) arch=arm-pi ;;
  esac
  
  if [ $os != "linux" ] && [ $os != "darwin" ]; then
    echo "Unsupported Platform: $os $arch" 1>&2
    exit 1
  fi
  
  if [ $arch != "x64" ] && [ $arch != "x86" ] && [ $arch != "arm-pi" ]; then
    echo "Unsupported Architecture: $os $arch" 1>&2
    exit 1
  fi
    
  case $1 in
    "help" )
      echo
      echo "Cloud9 Installer"
      echo
      echo "Usage:"
      echo "    install help                       Show this message"
      echo "    install install [name [name ...]]  Download and install a set of packages"
      echo "    install ls                         List available packages"
      echo
    ;;

    "ls" )
      echo "!node - Node.js"
      echo "!tmux - TMUX"
      echo "!nak - NAK"
      echo "!vfsextend - VFS extend"
      echo "!ptyjs - pty.js"
      echo "!collab - collab"
      echo "coffee - Coffee Script"
      echo "less - Less"
      echo "sass - Sass"
      echo "typescript - TypeScript"
      echo "stylus - Stylus"
      # echo "go - Go"
      # echo "heroku - Heroku"
      # echo "rhc - RedHat OpenShift"
      # echo "gae - Google AppEngine"
    ;;
    
    "install" )
      shift
    
      # make sure dirs are around
      mkdir -p "$C9_DIR"/bin
      mkdir -p "$C9_DIR"/tmp
      mkdir -p "$C9_DIR"/node_modules
      cd "$C9_DIR"
    
      # install packages
      while [ $# -ne 0 ]
      do
        if [ "$1" == "tmux" ]; then
          time tmux_install $os $arch
          shift
          continue
        fi
        time eval ${1} $os $arch
        shift
      done
      
      # finalize
      pushd "$C9_DIR"/node_modules/.bin
      for FILE in "$C9_DIR"/node_modules/.bin/*; do
        if [ `uname` == Darwin ]; then
          sed -i "" -E s:'#!/usr/bin/env node':"#!$NODE":g $(readlink $FILE)
        else
          sed -i -E s:'#!/usr/bin/env node':"#!$NODE":g $(readlink $FILE)
        fi
      done
      popd
      
      echo $VERSION > "$C9_DIR"/installed
      echo :Done.
    ;;
    
    "base" )
      echo "Installing base packages. Use --help for more options"
      start install nak ptyjs vfsextend collab
    ;;
    
    * )
      start base
    ;;
  esac
}

nak(){
  echo :Installing Nak
  "$NPM" install https://github.com/c9/nak/tarball/c9
}

ptyjs(){
  echo :Installing pty.js
  "$NPM" install node-gyp
  "$NPM" install pty.js@0.2.6
  
  HASPTY=`"$C9_DIR/node/bin/node" -e "console.log(require('pty.js'))" | grep createTerminal | wc -l`
  if [ $HASPTY -ne 1 ]; then
    echo "Unknown exception installing pty.js"
    echo `"$C9_DIR/node/bin/node" -e "console.log(require('pty.js'))"`
    exit 100
  fi
}

coffee(){
  echo :Installing Coffee Script
  "$NPM" install coffee
}

less(){
  echo :Installing Less
  "$NPM" install less
}

sass(){
  echo :Installing Sass
  "$NPM" install sass
}

typescript(){
  echo :Installing TypeScript
  "$NPM" install typescript  
}

stylus(){
  echo :Installing Stylus
  "$NPM" install stylus  
}

# go(){
  
# }

# heroku(){
  
# }

# rhc(){
  
# }

# gae(){
  
# }

start $@

# cleanup tmp files
rm -rf "$C9_DIR/tmp"
