#! /usr/bin/env bash
# Author: Aaron Kuehler
# Purpose: Install the dotfiles

DOTFILES_HOME=$HOME/.files

function bootstrap() {
    if [[ $OSTYPE =~ ^darwin ]]; then
        # make sure brew is installed when we are running on darwin
        if ! [ -x "$(command -v brew)" ]; then
            ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
        brew update
        brew tap homebrew/cask-versions
        # install bash and bash-completion
        if [ "$( brew info --json=v1 bash | jq .[0].installed[].version )" == "" ]; then
            echo "installing bash"
            brew install bash
        else
            echo "bash already installed"
        fi
        if [ "$( brew info --json=v1 bash-completion | jq .[0].installed[].version )" == "" ]; then
            echo "installing bash-completion"
            brew install bash-completion
        else
            echo "bash-completion already installed"
        fi
        # add new bash to accepted shells
        if [ ! "$( grep "/\usr\/local\/bin\/bash" /etc/shells )" ]; then
            echo "adding new bash to accepted shells"
            echo "/usr/local/bin/bash" > sudo cat - > /etc/shells
        fi
        # set our shell to the newer bash
        if [ ! "$SHELL" == "/usr/local/bin/bash" ]; then
            echo "changing shell for ${LOGNAME}"
            sudo dscl . -create /Users/$LOGNAME UserShell /usr/local/bin/bash
        fi
        # install emacs if it's not installed
        if [ "$( brew info --json=v1 emacs | jq .[0].installed[].version )" == "" ]; then
            brew install emacs
        else
            echo "emacs already installed"
        fi
        if [ ! "$( brew cask list | grep emacs )" ]; then
            brew cask install emacs
        else
            echo "emacs cask already installed"
        fi
        # install needed binaries for my emacs setup
        EMACS_DEPS='aspell the_silver_searcher'
        for dep in $EMACS_DEPS; do
          if [ "$( brew info --json=v1 $dep | jq .[0].installed[].version )" == "" ]; then
            echo "installing $dep"
            brew install $dep
          else
            echo "$dep installed"
          fi
        done
    else
        # install flatpak if it's not installed
        if [ ! "$(command -v flatpak)" ]; then
            sudo apt install -y flatpak plasma-discover-backend-flatpak
        fi
        # install emacs if it's not installed
        if [ ! "$( flatpak list | grep emacs)" ]; then
            sudo flatpak install -y org.gnu.emacs
        fi
        # Install git so we can checkout our repo
        if [ ! "$(command -v git)" ]; then
            sudo apt install -y  git
        fi
    fi

}

function clone_or_update_repo() {
    if [ -e $DOTFILES_HOME ]; then
        echo "Updating $DOTFILES_HOME"
        cd $DOTFILES_HOME
        git pull
    else
        echo "Installing dotfiles to: $DOTFILES_HOME"
        git clone git@github.com:rendhalver/.files.git $DOTFILES_HOME
        cd $DOTFILES_HOME
    fi
}


function tangle_files() {
    DIR=`pwd`
    FILES=""

    for file in `ls *.org | grep -v README.org`; do
        FILES="$FILES \"$file\""
    done

    echo -e "Installing: \n$FILES"
    emacs -Q --batch \
          --eval \
          "(progn
            (require 'org)(require 'ob)(require 'ob-tangle)
             (mapc (lambda (file)
                     (find-file (expand-file-name file \"$DIR\"))
                     (org-babel-tangle)
                     (kill-buffer)) '($FILES)))"

    if [ -e $PWD/setup.org ]; then
        echo "Running setup"
        bash ./setup.sh
    fi
}

bootstrap
clone_or_update_repo
tangle_files

exit 0
