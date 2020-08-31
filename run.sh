#!/usr/bin/env bash
set -euo pipefail

if command -v racket > /dev/null; then
  echo "Already installed" > /dev/null
else
  if [[ "$#" -gt 0 ]]; then
    case $1 in
      --on-repl-it)
        PKG1="racket-common_7.7+ppa1-1~bionic1_all.deb"
        PKG2="racket_7.7+ppa1-1~bionic1_amd64.deb"
        
        SITE1="https://downloads.asterisell.com"
        SITE2="https://launchpad.net/~plt/+archive/ubuntu/racket/+files"

        install-pkg $SITE1/$PKG1 $SITE1/$PKG2 || install-pkg $SITE2/$PKG1 $SITE2/$PKG2
        
        ;;
    esac
  fi
fi

OPTS=""
if [[ "$#" -gt 0 ]]; then
  case $1 in
    --on-repl-it)
    OPTS="--config /home/runner/jam/repl-it-conf --collects /home/runner/.apt/usr/share/racket/collects"
    
    ;;
  esac
fi

if command -v racket > /dev/null 2>&1; then
  echo "Installed" > /dev/null
else
  echo "racket is not installed" 1>&2
  exit 1
fi

update_exec_racket () {
  sed -i 's/bindir=\"\/usr\/bin\"/bindir=\"\/home\/runner\/\.apt\/usr\/bin\"/g' /home/runner/.apt/usr/bin/$1

  sed -i 's/librktdir=\"\/usr\/lib\/racket\"/librktdir=\"\/home\/runner\/\.apt\/usr\/lib\/racket\"/g' /home/runner/.apt/usr/bin/$1

  sed -i 's/exec \"..bindir.\/racket\"/exec \"\/home\/runner\/\.apt\/usr\/bin\/racket\" --config \/home\/runner\/jam\/repl-it-conf --collects \/home\/runner\/.apt\/usr\/share\/racket\/collects /g' /home/runner/.apt/usr/bin/$1
}

if raco help > /dev/null 2>&1; then
  echo "Already patched" > /dev/null
else
  update_exec_racket "drracket"
  update_exec_racket "mred-text"
  update_exec_racket "mztext"
  update_exec_racket "plt-r5rs"
  update_exec_racket "raco"
  update_exec_racket "slideshow"
  update_exec_racket "gracket"
  update_exec_racket "mzc"
  update_exec_racket "pdf-slatex"
  update_exec_racket "plt-r6rs"
  update_exec_racket "scribble"
  update_exec_racket "swindle"
  update_exec_racket "gracket-text"
  update_exec_racket "mzpp"
  update_exec_racket "plt-games"
  update_exec_racket "plt-web-server"
  update_exec_racket "setup-plt"
  update_exec_racket "plt-help"
  update_exec_racket "slatex"
fi

if raco help > /dev/null 2>&1; then
  echo "raco can work" > /dev/null
else
  echo "raco can not work" 1>&2
  exit 1
fi

if raco pkg show Packrat -a | grep Packrat > /dev/null ; then
  echo "Packages are installed" > /dev/null
else
  raco pkg update --auto
fi

raco make main.rkt

if [[ "$#" -gt 1 ]]; then
  racket $OPTS main.rkt $2
else
  racket $OPTS main.rkt --start-web-app
fi
