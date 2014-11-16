# encoding: utf-8
require 'fileutils'
require 'logger'

require File.join File.dirname(__FILE__), "luigi/gitplumber"
require File.join File.dirname(__FILE__), "luigi/ShellSanitizer"

## requires a project_class
# project_class must implement: name, date, index

# implements everything not exposed to the outside
# TODO: make this all private
class LuigiInternal
  def init_logger
    @logger = Logger.new(STDERR)
    @logger.level = Logger::ERROR
    @logger.error "need a project_class" if @project_class.nil?
    @logger.progname = "LUIGI"
  end

  def init_dirs
    @dirs = {}
    @dirs[:storage]   = File.expand_path(File.join(@settings['path'], @settings['dirs']['storage']))
    @dirs[:working]   = File.join @dirs[:storage], @settings['dirs']['working']
    @dirs[:archive]   = File.join @dirs[:storage], @settings['dirs']['archive']
    @dirs[:templates] = File.expand_path File.join @settings['path'], @settings['dirs']['templates']
  end

  ##
  # Checks the existens of one of the three basic dirs.
  # dir can be either :storage, :working or :archive
  # and also :templates
  def check_dir(dir)
    File.exists? "#{@dirs[dir]}"
  end

  ##
  # Checks the existens of every thing required
  def check_dirs
    check_dir :storage and
    check_dir :working and
    check_dir :archive and
    check_dir :templates
  end

  # read the templates directory and cache paths
  def load_templates
    return false unless check_dir :templates
    files = Dir.glob File.join @dirs[:templates] , ?*
    @templates =  {}
    files.each{|file|
      name = File.basename file.split(?.)[0]
      @templates[name.to_sym] = file
    }
    return true
  end

  ##
  # creates new project_dir and project_file
  def _new_project_folder(name)
    unless check_dir(:working)
      @logger.info(File.exists? @dirs[:working])
      @logger.info "missing working directory!"
      return false
    end

    #  check of existing project with the same name
    folder = get_project_folder(name, :working)
    unless folder
      FileUtils.mkdir File.join @dirs[:working], name
      return get_project_folder(name, :working)
    else
      @logger.info "#{folder} already exists"
      return false
    end
  end

  ##
  # path to project file
  # there may only be one @file_extension file per project folder
  #
  # untested
  def get_project_file_path(name, dir=:working, year=Date.today.year)
      name = ShellSanitizer.process    name
      name = ShellSanitizer.clean_path name
      
    folder = get_project_folder(name, dir, year)
    if folder
      files = Dir.glob File.join folder, "*#{@file_extension}"
      warn "ambiguous amount of #{@file_extension} files in #{folder}" if files.length > 1
      warn "no #{@file_extension} files in #{folder}" if files.length < 1
      return files[0]
    end
    @logger.info "NO FOLDER get_project_folder(name = #{name}, dir = #{dir}, year = #{year})"
    return false
  end

  ##
  # lists project files from working directory
  def list_projects_working()
    folders = Dir.glob File.join @dirs[:working], "/*"
    paths = folders.map {|path| get_project_file_path File.basename path }
    puts "WARNING! one folder is not correct" if paths.include? false
    paths.keep_if{|v| v}
  end

  # lists project files from archive directory
  def list_projects_archive(year)
    folders = Dir.glob File.join @dirs[dir], year.to_s, "/*"
    paths = folders.map {|path| get_project_file_path (File.basename path), :archive, year }
    puts "WARNING! one folder is not correct" if paths.include? false
    paths.keep_if{|v| v}
  end

  ##
  # list projects
  # lists project files
  # (names actually contains paths)
  def list_projects_all
    names = []

    #first all archived projects, ever :D
    archives = Dir.glob File.join @dirs[:archive], "/*"
    archives.sort!
    archives.each do |a|
      paths = Dir.glob File.join a, "/*"
      year = File.basename a
      names += paths.map { |path|
        get_project_file_path (File.basename path), :archive, year
      }
    end

    #then all working projects
    names += list_projects :working

    return names
  end
end
