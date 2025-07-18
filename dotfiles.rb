#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'pathname'

INSTALL_FILE = 'install.rb'

$options = {}

# To install a package, we need to cd into the folder, load it's install.rb file and
def install_package(package) 
  puts "--------------------------------------"
  puts "Installing package: #{package}"
  FileUtils.cd(package) do
    if File.exist?(INSTALL_FILE) && File.readable?(INSTALL_FILE)
      load INSTALL_FILE
    else
      puts "Couldn't find #{INSTALL_FILE} for package #{package}. Doing nothing"
    end
  end
  puts "Done installing: #{package}"
end

#Create a link and make sure it is possible by checking creating every directory before
def ln_s(to, from)
  FileUtils.mkdir_p(File.dirname(File.absolute_path(from)), verbose: true)
  FileUtils.ln_s(to, from, verbose: true)
end

# This is a utility function used to create a 
def link(to, from)
  to = File.absolute_path(File.expand_path(to))
  from = File.absolute_path(File.expand_path(from))
  if File.exist?(from)
    if File.symlink?(from)
      if File.absolute_path(File.readlink(from)) == to
        puts "#{from} already links to #{to}, nothing to do"
      else
        puts "Unlinking #{from}"
        FileUtils.safe_unlink(from, verbose: true)
        ln_s(to, from)
      end
    else
      if $options[:force]
        puts "#{from} exists, forcing install, deleting it"
        FileUtils.rm_rf(from, verbose: true)
        ln_s(to, from) 
      else
        fail "#{from} exists and force was not set"
      end
    end
  else
    ln_s(to, from)
  end
end

# Recursively link all files in a directory structure, preserving the directory structure
# but linking files instead of directories
def link_files_recursively(source_dir, target_dir)
  source_path = File.absolute_path(File.expand_path(source_dir))
  target_path = File.absolute_path(File.expand_path(target_dir))
  
  Dir.glob(File.join(source_path, '**', '*'), File::FNM_DOTMATCH).each do |source_file|
    next if File.basename(source_file) == '.' || File.basename(source_file) == '..'
    next if File.directory?(source_file)
    
    # Calculate relative path from source directory
    relative_path = Pathname.new(source_file).relative_path_from(Pathname.new(source_path))
    target_file = File.join(target_path, relative_path)
    
    link(source_file, target_file)
  end
end


## Parse and execute based on arguments
parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./dotfiles.rb [options] packages..."

  opts.on("-f", "--force", "Force the installation") do |v|
    $options[:force] = v
  end
end

parser.parse!
if ARGV.length < 1 then
  fail "You need to specify at least one package"
else
  ARGV.map { |package| install_package package }
end
