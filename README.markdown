# Eric Seuret's Dot Files

These are my config files to configure a machine the way I like it.

Feel free to take inspirations ;-)

## Installation

### Getting the repository and updating

You first need to clone the repository:

    git clone git://github.com/ericst/dotfiles.git ~/.dotfiles

As I use pathogen and git to manage vim plugins you need to initialize and
update the git submodules.

    cd ~/.dotfiles
    git submodule init
    git submodule update
    
More informations about this can be found at
http://vimcasts.org/episodes/synchronizing-plugins-with-git-submodules-and-pathogen/
    

### Creating the symlinks

The creation of the symlinks is performed by invoking the install.py script:

    ./install.py

This script creates symbolic links pointing to the files in the current
directory. The files will have the same name as the original files with a
leading dot.

If a file already exists, the script will simply ignore it. There is an option
to force the install,

   ./install.py -f

This will delete any file in place and create the desired symlinks.
