#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'
require 'pathname'

INSTALL_FILE = 'install.rb'
DESCRIPTION_FILE = 'description.txt'

$options = {}

# Validate that a source file exists and is readable
def validate_source_file(source_path)
  unless File.exist?(source_path)
    fail "Source file does not exist: #{source_path}"
  end
  
  unless File.readable?(source_path)
    fail "Source file is not readable: #{source_path}"
  end
end

# Validate target path for security (prevent directory traversal)
def validate_target_path(target_path)
  expanded_target = File.expand_path(target_path)
  
  # Check for directory traversal attempts
  if target_path.include?('../') || target_path.include?('..\\')
    fail "Directory traversal detected in target path: #{target_path}"
  end
  
  # Ensure target is an absolute path after expansion
  unless Pathname.new(expanded_target).absolute?
    fail "Target path must resolve to an absolute path: #{target_path}"
  end
  
  expanded_target
end

# Prompt for confirmation on destructive operations
def confirm_destructive_operation(message, auto_yes = false)
  return true if auto_yes || !$options[:force]
  
  print "#{message} (y/n/a/q): "
  response = STDIN.gets.chomp.downcase
  
  case response
  when 'y', 'yes'
    true
  when 'a', 'all'
    $options[:auto_yes] = true
    true
  when 'q', 'quit'
    puts "Operation cancelled by user"
    exit 1
  else
    false
  end
end

# To install a package, we need to cd into the folder, load it's install.rb file and
def install_package(package) 
  puts "--------------------------------------"
  if $options[:dry_run]
    puts "[DRY RUN] Installing package: #{package}"
  else
    puts "Installing package: #{package}"
  end
  
  # Validate package directory exists
  package_path = File.join('packages', package)
  
  unless Dir.exist?(package_path)
    fail "Package directory does not exist: #{package_path}\nAvailable packages: #{get_available_packages.join(', ')}"
  end
  
  FileUtils.cd(package_path) do
    if File.exist?(INSTALL_FILE) && File.readable?(INSTALL_FILE)
      load INSTALL_FILE
    else
      fail "Couldn't find or read #{INSTALL_FILE} for package #{package}\nMake sure the file exists and is readable"
    end
  end
  
  if $options[:dry_run]
    puts "[DRY RUN] Done installing: #{package}"
  else
    puts "Done installing: #{package}"
  end
end

#Create a link and make sure it is possible by checking creating every directory before
def ln_s(to, from)
  if $options[:dry_run]
    puts "[DRY RUN] Would create directory: #{File.dirname(File.absolute_path(from))}"
    puts "[DRY RUN] Would create symlink: #{from} -> #{to}"
  else
    FileUtils.mkdir_p(File.dirname(File.absolute_path(from)), verbose: true)
    FileUtils.ln_s(to, from, verbose: true)
  end
end

# This is a utility function used to create a 
def link(to, from)
  # Validate source file exists
  validate_source_file(to)
  
  # Validate and expand target path
  from = validate_target_path(from)
  to = File.absolute_path(File.expand_path(to))
  
  if File.exist?(from)
    if File.symlink?(from)
      if File.absolute_path(File.readlink(from)) == to
        puts "#{from} already links to #{to}, nothing to do"
      else
        if $options[:dry_run]
          puts "[DRY RUN] Would replace existing symlink #{from} -> #{to}"
        elsif confirm_destructive_operation("Replace existing symlink #{from}?", $options[:auto_yes])
          puts "Unlinking #{from}"
          FileUtils.safe_unlink(from, verbose: true)
          ln_s(to, from)
        else
          puts "Skipping #{from}"
        end
      end
    else
      if $options[:force]
        if $options[:dry_run]
          puts "[DRY RUN] Would delete existing file #{from} and create symlink -> #{to}"
        elsif confirm_destructive_operation("#{from} exists and is not a symlink. Delete it?", $options[:auto_yes])
          puts "#{from} exists, forcing install, deleting it"
          FileUtils.rm_rf(from, verbose: true)
          ln_s(to, from)
        else
          puts "Skipping #{from}"
        end
      else
        if $options[:dry_run]
          puts "[DRY RUN] Would fail: #{from} exists and is not a symlink"
        else
          fail "#{from} exists and is not a symlink. Use --force to overwrite, or remove it manually"
        end
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
  
  # Validate source directory exists
  unless Dir.exist?(source_path)
    fail "Source directory does not exist: #{source_path}"
  end
  
  # Validate and expand target path
  target_path = validate_target_path(target_dir)
  
  Dir.glob(File.join(source_path, '**', '*'), File::FNM_DOTMATCH).each do |source_file|
    next if File.basename(source_file) == '.' || File.basename(source_file) == '..'
    next if File.directory?(source_file)
    
    # Calculate relative path from source directory
    relative_path = Pathname.new(source_file).relative_path_from(Pathname.new(source_path))
    target_file = File.join(target_path, relative_path)
    
    link(source_file, target_file)
  end
end

# Get all available packages by scanning the packages directory
def get_available_packages
  packages_dir = File.join(File.dirname(__FILE__), 'packages')
  return [] unless Dir.exist?(packages_dir)
  
  Dir.entries(packages_dir).select do |entry|
    path = File.join(packages_dir, entry)
    File.directory?(path) && entry != '.' && entry != '..'
  end.sort
end

# Get package description from description.txt file
def get_package_description(package)
  packages_dir = File.join(File.dirname(__FILE__), 'packages')
  desc_file = File.join(packages_dir, package, DESCRIPTION_FILE)
  
  if File.exist?(desc_file) && File.readable?(desc_file)
    File.read(desc_file).strip
  else
    "No description available"
  end
end

# Check if package has a valid install.rb file
def package_has_installer?(package)
  packages_dir = File.join(File.dirname(__FILE__), 'packages')
  install_file = File.join(packages_dir, package, INSTALL_FILE)
  File.exist?(install_file) && File.readable?(install_file)
end

# List all available packages with descriptions
def list_packages
  puts "Available packages:"
  puts "==================="
  
  packages = get_available_packages
  if packages.empty?
    puts "No packages found in packages/ directory"
    return
  end
  
  packages.each do |package|
    description = get_package_description(package)
    has_installer = package_has_installer?(package)
    status_indicator = has_installer ? "✓" : "✗"
    
    puts "#{status_indicator} #{package.ljust(15)} - #{description}"
  end
  
  puts "\n✓ = Has install.rb, ✗ = Missing install.rb"
end

# Extract links from a package's install.rb without executing it
def get_package_links(package)
  packages_dir = File.join(File.dirname(__FILE__), 'packages')
  install_file = File.join(packages_dir, package, INSTALL_FILE)
  links = []
  
  return links unless File.exist?(install_file) && File.readable?(install_file)
  
  # Read the install.rb file and extract link calls
  content = File.read(install_file)
  content.scan(/link\s+['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]/) do |source, target|
    # Convert relative paths to absolute for source (relative to package directory)
    source_path = File.absolute_path(File.expand_path(source, File.join(packages_dir, package)))
    target_path = File.expand_path(target)
    links << { source: source_path, target: target_path, type: :file }
  end
  
  # Also check for link_files_recursively calls
  content.scan(/link_files_recursively\s+['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]/) do |source, target|
    source_path = File.absolute_path(File.expand_path(source, File.join(packages_dir, package)))
    target_path = File.expand_path(target)
    links << { source: source_path, target: target_path, type: :recursive }
  end
  
  links
end

# Check the installation status of a package
def check_package_status(package)
  return { status: :no_installer, links: [] } unless package_has_installer?(package)
  
  links = get_package_links(package)
  link_statuses = []
  
  links.each do |link|
    if link[:type] == :recursive
      # For recursive links, check if target directory exists and has symlinks
      if Dir.exist?(link[:target])
        link_statuses << { 
          target: link[:target], 
          status: :installed, 
          type: :recursive,
          note: "Directory exists (recursive link)"
        }
      else
        link_statuses << { 
          target: link[:target], 
          status: :missing, 
          type: :recursive,
          note: "Directory missing"
        }
      end
    else
      # For regular links, check symlink status
      if File.exist?(link[:target])
        if File.symlink?(link[:target])
          actual_target = File.readlink(link[:target])
          if File.absolute_path(actual_target) == link[:source]
            link_statuses << { 
              target: link[:target], 
              status: :installed, 
              type: :file,
              note: "Correctly linked"
            }
          else
            link_statuses << { 
              target: link[:target], 
              status: :wrong_target, 
              type: :file,
              note: "Links to wrong target: #{actual_target}"
            }
          end
        else
          link_statuses << { 
            target: link[:target], 
            status: :not_symlink, 
            type: :file,
            note: "File exists but is not a symlink"
          }
        end
      else
        link_statuses << { 
          target: link[:target], 
          status: :missing, 
          type: :file,
          note: "File missing"
        }
      end
    end
  end
  
  # Determine overall package status
  if link_statuses.empty?
    overall_status = :no_links
  elsif link_statuses.all? { |ls| ls[:status] == :installed }
    overall_status = :fully_installed
  elsif link_statuses.any? { |ls| ls[:status] == :installed }
    overall_status = :partially_installed
  else
    overall_status = :not_installed
  end
  
  { status: overall_status, links: link_statuses }
end

# Show installation status of all packages
def show_status
  puts "Package installation status:"
  puts "============================="
  
  packages = get_available_packages
  if packages.empty?
    puts "No packages found in packages/ directory"
    return
  end
  
  packages.each do |package|
    status_info = check_package_status(package)
    
    case status_info[:status]
    when :no_installer
      puts "✗ #{package.ljust(15)} - No install.rb file"
    when :no_links
      puts "? #{package.ljust(15)} - No links defined"
    when :fully_installed
      puts "✓ #{package.ljust(15)} - Fully installed (#{status_info[:links].length} links)"
    when :partially_installed
      installed_count = status_info[:links].count { |l| l[:status] == :installed }
      total_count = status_info[:links].length
      puts "~ #{package.ljust(15)} - Partially installed (#{installed_count}/#{total_count} links)"
    when :not_installed
      puts "✗ #{package.ljust(15)} - Not installed (#{status_info[:links].length} links missing)"
    end
    
    # Show detailed link status if there are issues
    if status_info[:status] == :partially_installed || status_info[:status] == :not_installed
      status_info[:links].each do |link|
        next if link[:status] == :installed
        puts "    #{link[:target]} - #{link[:note]}"
      end
    end
  end
  
  puts "\n✓ = Fully installed, ~ = Partially installed, ✗ = Not installed, ? = No links"
end


## Parse and execute based on arguments
parser = OptionParser.new do |opts|
  opts.banner = "Usage: ./dotfiles.rb [options] packages..."

  opts.on("-f", "--force", "Force the installation") do |v|
    $options[:force] = v
  end
  
  opts.on("-l", "--list", "List available packages") do |v|
    $options[:list] = v
  end
  
  opts.on("-s", "--status", "Show installation status of packages") do |v|
    $options[:status] = v
  end
  
  opts.on("-y", "--yes", "Automatically answer yes to all prompts") do |v|
    $options[:auto_yes] = v
  end
  
  opts.on("-n", "--dry-run", "Show what would be done without executing") do |v|
    $options[:dry_run] = v
  end
end

parser.parse!

# Handle special commands
if $options[:list]
  list_packages
  exit 0
end

if $options[:status]
  show_status
  exit 0
end

# Regular package installation
if ARGV.length < 1 then
  fail "You need to specify at least one package"
else
  ARGV.map { |package| install_package package }
end
