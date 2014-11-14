require 'date'
require 'logger'


class LuigiProject # TO BE LuigiProject

  attr_reader :using_erb

  # initializes the project
  # opens project from :path.
  # if :template_path is given it will create a fresh project from template first
  # and store it in path
  def initialize hash
    @path          = hash[:path]
    @settings      = hash[:settings]
    @template_path = hash[:template_path]
    @data          = hash[:data]

    @logger = Logger.new STDOUT
    @logger.progname = "LuigiProject"

    unless @template_path.nil?
      create @template_path
    end

    open @path
  end

  # attempting to fill erb if template ends in .erb
  # filling with @settings[:defaults]
  def create template_path

    @using_erb = File.extname(@template_path) == ".erb"

    template_basename = File.basename @template_path
    template_basename = File.basename @template_path, ".erb" if using_erb

    raise "Project file extension error!" unless File.extname(@path) == @settings['project_file_extension']
    raise "Template file extension error!" unless File.extname(template_basename) == @settings['project_file_extension']
    raise "Template does not exist!" unless File.exists? @template_path
    raise "Project file already exists! (#{@path})" if File.exists? @path


    if @using_erb
      data = @data
      settings = @settings
      engine=ERB.new(File.read(@template_path),nil,'<>')
      result = engine.result(binding)


        #puts "writing into #{@path}"
        file = File.new @path, "w"
        result.lines.each do |line|
          file.write line
        end
        file.close

    else
      FileUtils.cp @template_path, @path
    end
  end

  # opens project form path
  def open path
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

  def STATUS
    :ok # at least :ok or anything else
  end

  def date
    return Date.today
  end

end
