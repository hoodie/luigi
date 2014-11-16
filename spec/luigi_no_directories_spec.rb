require 'pp'
require 'fileutils'
require 'yaml'

require 'paint'

require File.dirname(__FILE__) + '/spec_helper'

$SETTINGS = YAML::load(File.open(File.join File.dirname(__FILE__), "../default-settings.yml"))
$SETTINGS['path'] = "."


describe Luigi do

  context "with no directories yet" do
    before :each do
      @spec_template = File.join FileUtils.pwd, './templates/default.yml.erb'
      @plumber  = described_class.new $SETTINGS, LuigiProject
    end

    after :each do
      puts Paint["working created", :red] if Dir.glob(?*).include? "working"
      FileUtils.rm_rf File.expand_path $SETTINGS['dirs']['storage']
    end


    describe "#check_dir" do

      it "notices missing storage directory" do
        expect(File).not_to exist $SETTINGS['dirs']['storage']
        expect(@plumber.check_dir :storage).to be_falsey
      end

      it "notices missing working directory" do
        expect(File).not_to exist @plumber.dirs[:working]
        expect( @plumber.check_dir :working ).to be_falsey
      end

      it "notices missing archive directory" do
        expect(File).not_to exist $SETTINGS['dirs']['archive']
        expect( @plumber.check_dir :archive ).to be_falsey
      end

      it "notices missing templates directory" do
        expect(File).not_to exist @plumber.dirs[:templates]
        expect( @plumber.check_dir :templates).to be_falsey
      end
    end

    describe "#create_dir" do
      it "refuses to create working directory without the storage directory" do
        expect(File).not_to exist @plumber.dirs[:storage]
        expect(@plumber.create_dir :working).to be_falsey
        expect(File).not_to exist @plumber.dirs[:working]
      end

      it "refuses to create archive directory without the storage directory" do
        expect(File).not_to exist $SETTINGS['dirs']['archive']
        expect(@plumber.create_dir :archive).to be_falsey
        expect(File).not_to exist $SETTINGS['dirs']['archive']
      end
    end

    describe "#_new_project_folder" do
      it "refuses to create a new project_folder" do
        expect(File).not_to exist $SETTINGS['dirs']['working']
        expect(@plumber._new_project_folder("new_project_folder")).to be_falsey
      end
    end

    describe "#create_dir" do
      it "creates the storage directory" do
        expect(File).not_to exist $SETTINGS['dirs']['storage']
        @plumber.create_dir :storage
        expect(File).to exist @plumber.dirs[:storage]
        expect(File).to exist $SETTINGS['dirs']['storage']
      end

      it "creates the working directory" do
        @plumber.create_dir :storage
        expect(File).not_to exist @plumber.dirs[:working]
        @plumber.create_dir :working
        expect(File).to exist @plumber.dirs[:working]
      end

      it "creates the archive directory" do
        @plumber.create_dir :storage
        expect(File).not_to exist @plumber.dirs[:archive]
        @plumber.create_dir :archive
        expect(File).to exist @plumber.dirs[:archive]
      end
    end

    #describe "#list_projects" do
    #  it "refuses to list projects if file does not exist" do
    #    @plumber.list_projects).to be_falsey
    #  end
    #end

  end
end
