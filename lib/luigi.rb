# encoding: utf-8
require 'fileutils'
require 'logger'
require 'hashr'

require File.join File.dirname(__FILE__), "luigi_internal"
require File.join File.dirname(__FILE__), "luigi_project"
require File.join File.dirname(__FILE__), "luigi_projects_list"
require File.join File.dirname(__FILE__), "luigi/gitplumber"
require File.join File.dirname(__FILE__), "luigi/ShellSanitizer"

## requires a project_class
# project_class must implement: name, date
# TODO
class Luigi < LuigiInternal

  attr_reader :dirs,
    :project_paths,
    :opened_sort,
    :templates,
    :settings

  #attr_writer :project_class

  include GitPlumber

  def initialize(settings, project_class = nil)
    @settings        = Hashr.new settings
    @project_class   = project_class
    @file_extension  = settings['project_file_extension']
    @file_extension  ||= ".yml"
    @using_git       = settings['use_git']

    init_logger()
    init_dirs()
    load_templates()
  end

  ##
  # create a dir
  # dir can be either :storage, :working or :archive
  def create_dir(dir)
    unless check_dir(dir)
      if dir == :storage or check_dir :storage
        FileUtils.mkdir @dirs[dir]
        @logger.info "Created \"#{dir.to_s}\" Directory (#{@dirs[dir]})"
        return true
      end
      @logger.error "No storage dir."
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

    template_path = @templates[template]
    raise "No such template." unless @templates.keys.include? template
    raise "Template file does not exists." unless File.exists? template_path
    data[:project_name] = name

    # create project folder
    folder = _new_project_folder(name)

    if folder
      target = File.join folder, name+@file_extension
      # project will load template and
      project = @project_class.new({
        :path          => target,
        :settings      => @settings,
        :template_path => template_path,
        :data          => data }
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
  def _open_projects(dir=:working, sort = :date, year=Date.today.year)
    #TODO perhaps cache projects
    if dir==:all
      opened_paths    = list_project_files_all
    else
      opened_paths    = list_project_files dir, year
    end

    projects = []
    opened_paths.each {|path|
      project = open_project_from_path(path)
      projects <<  project if project.status == :ok
    }
    projects = LuigiProjectsList.new sort_projects(projects, sort)
    return projects
  end

  # sorts array of project_class
  def sort_projects(projects, sort = :date)
      raise "sort must be a Symbol, not a #{sort.class} (#{sort})" unless sort.class == Symbol
      if @project_class.method_defined? sort
          projects.sort_by! {|project| project.method(sort).call}
          return projects
      else raise "#{@project_class} does not implement #{sort}()"
      end
      return false
  end


  def open_projects_all(sort = :date)
    _open_projects :all , sort, Date.today.year
  end

  def open_projects_working(sort = :date)
    _open_projects :working, sort, Date.today.year
  end

  def open_projects_archive(year,sort = :date)
    _open_projects :archive, sort, year
  end


  # returns project path
  def lookup_path_by_name(name, dir = :working, year = Date.today.year)
    projects = map_project_files(dir, year)
    matches = projects.keys.select{|k| k.downcase.include? name.downcase}
    return matches.each{|match|
      projects[match]
    }
  end

  # returns opened project
  # needs to open projects in order to sort
  def lookup_by_num(num, dir= :working, sort=:date, year= Date.today.year)
    projects =  _open_projects(dir, sort, year)
    projects.each{|p| puts "#{p.date}: #{p.name}" }
    #num = num.to_i - 1 if num.class == String and num =~ /^\d*$/
    num = num.to_i - 1
    project =  projects[num]
    @logger.error "there is no project ##{num+1}" if project.nil?
    return project
  end

  # opens a project from name
  # TODO implement archive lookup
  def open_project_from_name project_name
    return false unless project_name.class == String
    project_name = ShellSanitizer.process    project_name
    project_name = ShellSanitizer.clean_path project_name
    path = get_project_file_path project_name
    return open_project_from_path path if path
    @logger.error "Patherror: #{project_name}"
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
      return map_project_files_working().keys()
    elsif dir == :archive
      return map_project_files_archive(year).keys()
    else
      @logger.error "unknown path #{dir}"
    end
  end

  ##
  # lists project files
  def list_project_files(dir = :working, year=Date.today.year)
    return unless check_dir(dir)
    if dir == :working
      return list_project_files_working()
    elsif dir == :archive
      return list_project_files_archive(year)
    else
      @logger.error "unknown path #{dir}"
      return []
    end
  end


  def filter_by projects, hash
    filtered_projets = []
    projects.each{|project|
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
  def archive_project(project, year = nil, prefix = '')
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
