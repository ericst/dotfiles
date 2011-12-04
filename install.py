#! /usr/bin/env python

"""
Script that create symlinks for my dotfiles
"""

import os
import shutil
import argparse

# Script configurations
ignore      = ['README.markdown', 'install.py', 'awesome']
homedir     = os.environ['HOME']
dotfilesdir = os.path.dirname(os.path.abspath(__file__))

# Creating the parsing arguments
parser = argparse.ArgumentParser(description='This is a dotfiles installation script')
parser.add_argument('-f', action='store_true', default=False, dest='force', help='Force installation by overriding current installed files')
options = parser.parse_args()

def createlink(source, destination):
  """Create a symlink from destination to source"""

  if os.path.exists(destination):

    if not options.force:
      print('{0} already exists and option -f not set -> Ignoring'.format(destination))

    else:
      if os.path.isfile(destination) or os.path.islink(destination):
        os.remove(destination)
      else:
        shutil.rmtree(destination)

      os.symlink(source, destination)
      print('Forced: {1} -> {0}'.format(source, destination))
      
  else:
    os.symlink(source, destination)
    print('{1} -> {0}'.format(source, destination))

def checkinstall(filename):
  """ Check if a file is in the ignore list """

  # Check if file is in the ignore list
  if filename in ignore:
    return False

  # Check if file is an hidden file
  if filename.startswith('.'):
    return False

  return True

def main():
  """Main function for the install"""

  files = [f for f in os.listdir(dotfilesdir) if checkinstall(f)]

  for f in files:
    createlink(os.path.join(dotfilesdir, f), os.path.join(homedir, '.'+f))

if __name__ == '__main__':
  main()
