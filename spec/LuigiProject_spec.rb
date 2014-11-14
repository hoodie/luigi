require 'fileutils'
require 'erb'
require 'yaml'

require File.dirname(__FILE__) + '/spec_helper'


describe LuigiProject do

  before do
    #test_path = "LuigiProject_spec"
    #FileUtils.rm_rf test_path if File.exists? test_path
    #FileUtils.mkdir test_path

    @settings = YAML::load(File.open(File.join File.dirname(__FILE__), "../default-settings.yml"))

    @project_path = File.join(@settings['dirs']['working'], "project_spec/")
    @project_file = File.join(@settings['dirs']['working'], "project_spec/project_spec.yml")
    @project_file2 = File.join(@settings['dirs']['working'], "project_spec/project_spec2.yml")

    FileUtils.mkdir_p @project_path
  end

  after :each do
    FileUtils.rm @project_file if File.exists? @project_file
    FileUtils.rm @project_file2 if File.exists? @project_file2
  end

  after do
    FileUtils.rm_rf @project_path
  end

  before :each do
    @project_erb = described_class.new(
      {:path => @project_file,
       :settings => @settings,
       :template_path => "templates/default.yml.erb",
       :data => {'project_name' => "spec_project"}
    })

    @project_static = described_class.new(
      {:path => @project_file2,
       :settings => @settings,
       :template_path => "templates/static.yml"})
  end

  it "knows when to use erb" do
    expect(@project_erb.using_erb).to be true
    expect(@project_static.using_erb).to be false
  end

  it "raises on non existing templates" do
    expect { project = described_class.new(
      {:path => File.join(@settings['dirs']['working'], "project_spec/project_spec.yml"),
       :settings => @settings, :template_path => "templates/not_there.yml.erb"}) }.to raise_error
  end

  it "raises on existing project files" do
    expect { project = described_class.new( {:path => "templates/default.yml.erb",
       :settings => @settings, :template_path => "templates/default.yml.erb"}) }.to raise_error
  end

  it "raises on invalid template file formats" do
    expect { project = described_class.new( {:path => File.join(@settings['dirs']['working'], "project_spec/project_spec.yml"),
       :settings => @settings, :template_path => "templates/default.xml.erb"}) }.to raise_error
  end

  it "raises on invalid project file formats" do
    expect { project = described_class.new( {:path => File.join(@settings['dirs']['working'], "project_spec/project_spec.xml"),
       :settings => @settings, :template_path => "templates/default.yml.erb"}) }.to raise_error
  end

  it "creates a new file from a static template" do
    expect(File).to exist @project_static.path 
  end

  it "creates a new file from an erb template" do
    expect(File).to exist @project_erb.path 
  end

  it "fills erb from project data"
  it "fills erb from default settings"

end
