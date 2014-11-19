# encoding: utf-8
require 'fileutils'
require 'logger'
require 'hashr'

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
    @dirs[:templates] = File.join @dirs[:storage], @settings['dirs']['templates']
  end

  ##
  # Checks the existens of one of the three basic dirs.
  # dir can be either :storage, :working or :archive
  # and also :templates
  def check_dir(dir)
    File.exists? @dirs[dir]
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
    #files = Dir.glob File.join @dirs[:templates] , ?*
    files = Dir.glob File.join(@dirs[:templates], "*{#{@file_extension}.erb,#{@file_extension}}")
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
  # derives path to project file from name
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

  # opens a project from path
  def open_project_from_path path
    project = @project_class.new({
      :path          => path,
      :settings      => @settings})
    return project if project.class == @project_class
    return false
  end




  ##
  # maps project names to files from working dir
  def map_project_files_working()
    map = {}
    folders = Dir.glob File.join @dirs[:working], "/*"
    paths = folders.map {|path| get_project_file_path File.basename path }
    paths.select!{|path| path} # removing faulty paths
    paths.each   {|path| map[File.basename path, @file_extension] = path }
    return map
  end

  ##
  # maps project names to files from working dir
  def map_project_files_archive(year = Date.today.year)
    map={}
    paths = Dir.glob File.join @dirs[:archive], year.to_s, "/*"
    names = paths.map {|path|
      file_path = get_project_file_path (File.basename path), :archive, year
      name = File.basename file_path, @file_extension
      map[name] = file_path
    }
    return map
  end

  ##
  # maps project names to files 
  def map_project_files(dir = :working, year=Date.today.year)
    return unless check_dir(dir)
    if dir == :working
      return map_project_files_working()
    elsif dir == :archive
      return map_project_files_archive year
    else
      @logger.error "unknown path #{dir}"
    end
  end

  ##
  # returns map of years to archive folders
  def map_archive_years
    map = {}
    Dir.glob(File.join @dirs[:archive], "/*").each{|path|
      map[File.basename path] = path
    }
    return map
  end




  ##
  # lists project files from working directory
  def list_project_files_working()
    map_project_files_working.values
  end

  # lists project files from archive directory
  def list_project_files_archive(year = Date.today.year)
    map_project_files_archive(year).values
  end

  ##
  # list projects
  # lists project files
  def list_project_files_all
    working = list_project_files_working
    archive = []
    map_archive_years.keys.each{|year|
      archive += list_project_files_archive(year)
    }
    return ( archive + working )
  end
end
