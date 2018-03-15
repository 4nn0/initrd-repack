#!/usr/bin/env bash
# Filename:      initrd-repack.sh
# Purpose:       inject archive in existing initrd
# Authors:       Andreas Nowak <andreas-nowak@gmx.net>
# License:       This file is licensed under the GPL v2 or any later version.
################################################################################
# vim: ai ts=2 sw=2 et sts=2 ft=sh
# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
################################################################################

# make sure we have the sbin directories in our PATH
PATH="${PATH}:/sbin:/usr/local/sbin:/usr/sbin"

# define function getfilesize before "set -e" {{{
  if stat --help >/dev/null 2>&1; then
    getfilesize='stat -c %s'        # GNU stat
  else
    getfilesize='stat -f %z'        # BSD stat
  fi
# }}}

# adjust variables if necessary through environment {{{
# work directory for creating the filesystem
WRKDIR='/tmp/'
# support mkisofs as well as genisoimage
ZCAT=$(which zcat)
if [ ! -x "$ZCAT" ]; then
  echo "Error: zcat not executeable"
  exit 1
fi
CPIO=$(which cpio)
if [ ! -x "$CPIO" ]; then
  echo "Error: cpio not executeable"
  exit 1
fi
# }}}

# helper stuff {{{
  set -e

  usage() {
    echo >&2 "Usage: $0 [-v] -i initrd.img.gz -a archive.deb [-t tempdir]"
    echo >&2 "
Options:
     -v         verbose output

     Examples:
     $0 -i boot.img.gz -a linux-image-extra-4.13.0-36-generic_4.13.0-36.40_amd64.deb -t /home/user/temp/
     Will extract files from linux-image-extra-4.13.0-36-generic_4.13.0-36.40_amd64.deb and inject it 
     to the given boot.img.gz
"
    [ -n "$1" ] && exit $1 || exit 1
  }
# }}}

# command line handling {{{
  [[ $# -gt 1 ]] || usage 1

  INITRD=''
  VERBOSE=''
  ARCHIVE=''
  while getopts vi:a:t: name; do
    case $name in
      i)   INITRD="$OPTARG";;
      t)   WRKDIR="$(readlink -f "$OPTARG")"; [ -n "$WRKDIR" ] || { echo "Could not read $OPTARG - exiting" >&2 ; exit 1 ; } ;;
      a)   ARCHIVE="$OPTARG";;
      v)   VERBOSE='true';;
      ?)   usage 2;;
    esac
  done

  if [ ! -f "$INITRD" -o -z "$INITRD" ]; then
    echo "Error: initrd $INITRD not found"
    exit 1
  fi

  if [ ! -f "$ARCHIVE" -o -z "$ARCHIVE" ]; then
    echo "Error: archive $ARCHIVE not found"
    exit 1
  fi
# }}}

# preparation {{{
  MKTEMP=$(which mktemp)
  if [ ! -x "$MKTEMP" ]; then
    echo "Error: mktemp not executeable"
    exit 1
  fi
  TMPDIR=$($MKTEMP -d --tmpdir=${WRKDIR} --suffix='-repack-initrd')
  mkdir -p $TMPDIR/unpack
  INITRDPATH=$(realpath $INITRD)
  ARCHIVEPATH=$(realpath $ARCHIVE)
# }}}

# unpack and build {{{
  cd $TMPDIR/unpack
  $ZCAT $INITRD | $CPIO -idmv 1>/dev/null 2>&1 ||:
  DPKG=$(which dpkg)
  if [ ! -x "$DPKG" ]; then
    echo "Error: dpkg not executeable"
    exit 1
  fi
  $DPKG -x $ARCHIVEPATH $TMPDIR/unpack
  find . | cpio -o -c 2>/dev/null | gzip -9 > $INITRDPATH.new
  echo "Info: New initrd $INITRD.new has been created"
# }}}

# cleanup {{{
  rm -rf $TMPDIR
# }}}
