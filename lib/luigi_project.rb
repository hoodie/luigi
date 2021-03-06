require 'date'
require 'logger'


class LuigiProject

  attr_reader :status, :using_erb

  # initializes the project
  # opens project from :path.
  # if :template_path is given it will create a fresh project from template first
  # and store it in path
  def initialize hash
    @path          = hash[:path]
    @settings      = hash[:settings]
    @template_path = hash[:template_path]
    @data          = hash[:data]
    @data        ||= {}

    @logger = Logger.new STDOUT
    @logger.progname = "LuigiProject"

    unless @template_path.nil?
      create @template_path
    end

    open @path
  end

  # attempting to fill erb if template ends in .erb
  # filling with @settings[:defaults]
  def create(template_path)
    @using_erb = File.extname(@template_path) == ".erb"

    template_basename = File.basename @template_path
    template_basename = File.basename @template_path, ".erb" if using_erb

    raise "Project file extension error!" unless File.extname(@path) == @settings['project_file_extension']
    raise "Template file extension error!" unless File.extname(template_basename) == @settings['project_file_extension']
    raise "Template does not exist!" unless File.exists? @template_path
    raise "Project file already exists! (#{@path})" if File.exists? @path

    if @using_erb
      create_with_erb(template_path)
    else
      FileUtils.cp @template_path, @path
    end
  end

  def fill_template
    return binding
  end

  def create_with_erb template_path
    engine=ERB.new(File.read(template_path),nil,'<>')
    b = fill_template()
    result = engine.result(b)

    file = File.new @path, "w"
    result.lines.each do |line|
      file.write line
    end
    file.close
  end

  # opens project form path
  def open path
    @path = path
  end

  # returns path
  def path
    @path
  end

  # returns name
  def name
    File.basename @path, ".yml"
  end

  # returns index
  def index
    123
  end

  def date
    return Date.today
  end

end
