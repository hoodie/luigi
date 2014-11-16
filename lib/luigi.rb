# encoding: utf-8
require 'fileutils'
require 'logger'

require File.join File.dirname(__FILE__), "luigi_internal"
require File.join File.dirname(__FILE__), "luigi/gitplumber"
require File.join File.dirname(__FILE__), "luigi/ShellSanitizer"

## requires a project_class
# project_class must implement: name, date
# TODO
class Luigi < LuigiInternal

  attr_reader :dirs,
    :opened_projects,
    :project_paths,
    :opened_paths,
    :opened_sort,
    :templates

  #attr_writer :project_class

  include GitPlumber

  def initialize(settings, project_class = nil)
    @settings        = settings
    @opened_projects = []
    @project_class   = project_class
    @file_extension  = settings['project_file_extension']
    @using_git       = settings['use_git']

    init_logger()
    init_dirs()
  end

  ##
  # create a dir
  # dir can be either :storage, :working or :archive
  def create_dir(dir)
    unless check_dir(dir)
      if dir == :storage or check_dir :storage
        FileUtils.mkdir "#{@dirs[dir]}"
        @logger.info "Created \"#{dir.to_s}\" Directory (#{@dirs[dir]})"
        return true
      end
      @logger.error "no storage dir"
    end
    return false
  end
 

  ##
  # creates new project_dir and project_file
  # returns project object
  def new_project(_name, template = :default, data = {})
    _name = ShellSanitizer.process _name
    name = ShellSanitizer.clean_path _name

    load_templates()

    template = @templates[template]

    # create project folder
    folder = _new_project_folder(name)

    if folder
      target = File.join folder, name+@file_extension
      # project will load template and 
      project = @project_class.new({
        :path=>target,
        :settings=>@settings,
        :template_path=>template,
        :data=>data }
                                  )

    else
      return false
    end

  end


  ##
  # produces an Array of @project_class objects
  # sorted by date (projects must implement date())
  # if sort is foobar, projects must implement foobar()
  # output of (foobar must be comparable)
  #
  # untested
  def open_projects(dir=:working, year=Date.today.year, sort = :date)
    if dir==:all
      @opened_paths    = list_projects_all
    else
      @opened_paths    = list_projects dir, year 
    end

    @project_paths   = {}
    @opened_paths.each {|path|
      project = @project_class.new :path=>path
      if project.STATUS == :ok
        @opened_projects = @opened_projects + [ project ]
      end
      @project_paths[project.name] = path
    }
    sort_projects(sort)
    return true
  end

  def open_project project
    return false unless project.class == String
    project = ShellSanitizer.process    project
    project = ShellSanitizer.clean_path project
    open_projects()
    project = lookup(project)
    return project if project.class == @project_class
  end


  ##
  # produces an Array of @project_class objects
  #
  # untested
  def open_projects_all(sort = :date)
    @opened_paths    = list_projects_all
    open_projects :all, year=nil, sort
  end

  def [] term
    lookup term
  end

  def lookup_path(name, sort = nil)
    p = lookup(name)
    return @project_paths[p.name] unless p.nil?
    @logger.error "there is no project #{name}"
    return false
  end
  
  
  def lookup(name, sort = nil)
    sort_projects sort unless sort == nil or @opened_sort == sort
    name = name.to_i - 1 if name =~ /^\d*$/
    if name.class == String
      name_map = {}
      @opened_projects.each {|project| name_map[project.name] = project}
      project = name_map[name]
      @logger.error "there is no project \"#{name}\"" if project.nil?
    elsif name.class == Fixnum
      project =  @opened_projects[name]
      @logger.error "there is no project ##{name+1}" if project.nil?
    end
    return project
  end
  
  
  def sort_projects(sort = :date)
      fail "sort must be a Symbol" unless sort.class == Symbol
      if @project_class.method_defined? sort
          @opened_projects.sort_by! {|project| project.method(sort).call}
      else fail "#{@project_class} does not implement #{sort}()"
      end
      return true
  end
  


  ##
  # Path to project folder
  # If the folder exists
  # dir can be :working or :archive 
  #
  # TODO untested for archives
  def get_project_folder( name, dir=:working, year=Date.today.year )
    name = ShellSanitizer.process    name
    name = ShellSanitizer.clean_path name
    year = year.to_s
    target = File.join @dirs[dir], name       if dir == :working
    target = File.join @dirs[dir], year, name if dir == :archive
    return target if File.exists? target
    false
  end

  ##
  # list projects
  # lists project files
  def list_project_names(dir = :working, year=Date.today.year)
    return unless check_dir(dir)
    if dir == :working
      paths = Dir.glob File.join @dirs[:working], "/*"
      names = paths.map {|path| File.basename path }
    elsif dir == :archive
      paths = Dir.glob File.join @dirs[:archive], year.to_s, "/*"
      names = paths.map {|path|
        file_path = get_project_file_path (File.basename path), :archive, year
        name = File.basename file_path, @file_extension
      }
      return names
    else
      @logger.error "unknown path #{dir}"
    end
  end

  ##
  # lists project files
  def list_projects(dir = :working, year=Date.today.year)
    return unless check_dir(dir)
    if dir == :working
      return list_projects_working()
    elsif dir == :archive
      return list_projects_archive(year)
    else
      @logger.error "unknown path #{dir}"
      return []
    end
  end


  def filter_by hash
    filtered_projets = []
    @opened_projects.each{|project|
      hash.each{|key,value|
        field = project.data(key)
        if field and field.to_s.downcase.include? value
          filtered_projets.push project
          break
        end
      }
    }
    return filtered_projets
  end

  ##
  #  Move to archive directory
  #  @name 
  ## Luigi.archive_project should use ShellSanitizer
  def archive_project(project_name, year = nil, prefix = '')
    project = open_project project_name
    return false unless project.class == @project_class
    
    year ||= project.date.year
    year_folder = File.join @dirs[:archive], year.to_s
    FileUtils.mkdir year_folder unless File.exists? year_folder

    project_folder = get_project_folder project.name, :working
    if prefix and prefix.length > 0
      archived_name = project.name.prepend(prefix + "_")
      target = File.join year_folder, archived_name
    else
      target = File.join year_folder, project.name
    end

    return false unless project_folder
    return false if list_project_names(:archive, year).include? project.name

    @logger.info "moving: #{project_folder} to #{target}" if target and project_folder

    FileUtils.mv project_folder, target
    if open_git()
      git_update_path project_folder
      git_update_path target
    end
    return target
  end

  ##
  #  Move to archive directory
  def unarchive_project(project, year = Date.today.year)
    project = open_project project
    return false unless project.class == @project_class

    path         = project.path
    cleaned_name = File.basename(path,@file_extension)
    source       = get_project_folder project.name, :archive, year
    target       = File.join @dirs[:working], cleaned_name
    return false unless source

    @logger.info "moving #{source} to #{target}"

    unless get_project_folder cleaned_name
      FileUtils.mv source, target
      if open_git()
        git_update_path source
        git_update_path target
      end
      return true
    else
      return false
    end
  end

end
