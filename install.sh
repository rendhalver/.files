#! /bin/bash
# Author: Aaron Kuehler
# Purpose: Install the dotfiles

DOTFILES_HOME=$HOME/.files

function bootstrap() {
    if [[ $OSTYPE == darwin?? ]]; then
        # make sure brew is installed when we are running on darwin
        if ! [ -x "$(command -v brew)" ]; then
            ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
        brew update
        # install emacs if it's not installed
        if [ -x "$(command -v emacs)" ]; then
            brew cask install emacs
            brew install emacs
        fi
    else
        # install emacs if it's not installed
        if [ -x "$(command -v emacs)" ]; then
            sudo apt install emacs
        fi
        # Install git so we can checkout our repo
        if [ -x "$(command -v git)" ]; then
            sudo apt install git
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
