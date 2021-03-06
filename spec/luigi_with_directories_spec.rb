require 'pp'
require 'fileutils'
require 'yaml'

require 'paint'

require File.dirname(__FILE__) + '/spec_helper'

$SETTINGS = YAML::load(File.open(File.join File.dirname(__FILE__), "../default-settings.yml"))
$SETTINGS['path'] = "."

reset_path = File.join $SETTINGS['path'], $SETTINGS['dirs']['storage']
FileUtils.rm_rf reset_path if File.exists? reset_path


describe Luigi do

  before :all do
    #puts File.expand_path File.join FileUtils.pwd, './templates/default.yml.erb'
  end

  after :each do
    puts Paint["working created", :red] if Dir.glob(?*).include? "working"
    FileUtils.rm_rf @plumber.dirs[:storage]
  end

  before :each do
    @spec_template = File.expand_path File.join FileUtils.pwd, './templates/default.yml.erb'

    @plumber  = described_class.new $SETTINGS, LuigiProject

    @plumber.create_dir :storage
    @plumber.create_dir :working
    @plumber.create_dir :archive
    @plumber.create_dir :templates

    FileUtils.cp @spec_template, @plumber.dirs[:templates]

    @plumber1 = described_class.new $SETTINGS, LuigiProject
    @plumber2 = described_class.new $SETTINGS, LuigiProject
    @plumber3 = described_class.new $SETTINGS, LuigiProject
  end


  context "with existing directories" do

    describe described_class, "#check_dir" do
      it "checks existing storage directory" do
        expect(@plumber.check_dir (:storage) ).to be_truthy
        expect(File).to exist @plumber.dirs[:storage]
      end

      it "checks existing working directory" do
        expect( @plumber.check_dir :working ).to be_truthy
      end

      it "checks existing archive directory" do
        expect( @plumber.check_dir :archive ).to be_truthy
      end

      it "checks existing templates directory" do
        expect( @plumber.check_dir :templates ).to be_truthy
      end
    end

    describe described_class, "#load_templates" do
      it "finds its template dir" do
        $SETTINGS['dirs']['templates']

        FileUtils.rm_r(@plumber.dirs[:templates])

        expect(File).to exist(@spec_template)
        expect(File).to exist(@plumber.dirs[:storage])


        # preparing test env on the fly
        # creating manually
        expect(File).not_to exist(@plumber.dirs[:templates])
        FileUtils.mkdir @plumber.dirs[:templates]
        expect(File).to exist(@plumber.dirs[:templates])

        # creating with create_dir
        FileUtils.rm_r(@plumber.dirs[:templates])
        @plumber.create_dir :templates
        expect(File).to exist(@plumber.dirs[:templates])

        FileUtils.cp @spec_template, @plumber.dirs[:templates]

        expect(File).to exist(@plumber.dirs[:templates])

        expect(File).to exist @plumber.dirs[:templates]
        expect( @plumber.check_dir :templates).to be_truthy
      end

      it "finds its template files" do
        expect(File).to exist @spec_template
        expect(@plumber.load_templates).to be_truthy
        expect(@plumber.templates). to eq({default:(@plumber.dirs[:templates]+'/default.yml.erb')})
      end
    end


    describe described_class, "#_new_project_folder()" do
      it "creates a new project folder" do
        path = @plumber._new_project_folder "new_project0"
        expect(File).to exist path
      end

      it "refuses to create a project folder with existing name" do
        expect(@plumber._new_project_folder("duplicate")).to be_truthy
        expect(@plumber._new_project_folder("duplicate")).to be_falsey
      end

      it "deletes empty project path"
    end

    describe described_class, "#new_project" do
      it "sanitizes names prior to creating new projects with forbidden characters" do
        subfolder       = @plumber.new_project("sub/folder")
        hiddenproject   = @plumber1.new_project(".hidden_project")
        canceledproject = @plumber2.new_project("canceled catering")

        expect(subfolder    ).to be_truthy
        expect(hiddenproject).to be_truthy

        expect( @plumber.get_project_folder("sub_folder")).to be_truthy
        expect(File).to exist  File.join(@plumber.dirs[:working], "sub_folder" )

        expect(@plumber1.get_project_folder("hidden_project")).to be_truthy
        expect(File).to exist  File.join(@plumber.dirs[:working], "hidden_project" )

        expect(@plumber2.get_project_folder("canceled catering")).to be_truthy
        expect(File).to exist  File.join(@plumber.dirs[:working], "canceled catering" )
      end

      it "creates a new project" do
        expect(@plumber.new_project("new_project1")).to be_truthy
        expect(@plumber.new_project("new_project1")).to be_falsey
        expect(@plumber.new_project("new_project2")).to be_truthy
      end

      it "creates a new project with spaces in name" do
        name = "  fun project "
        @plumber.new_project(name)
        expect(@plumber.get_project_file_path(name)).to be_truthy
        expect(@plumber.get_project_file_path(name.strip)).to be_truthy
        expect(File).to exist @plumber.get_project_file_path(name.strip)
      end
    end

## TODO test get_project_folder for :archive
    describe described_class, "#get_project_folder" do
      it "returns false for missing project folder" do
        expect(@plumber.get_project_folder("nonexistent_project")).to be_falsey
      end

      it "returns path to project folder" do
        expect(@plumber.new_project("new_project1")).to be_truthy
        expect(@plumber.get_project_folder("new_project1")).to be_truthy
        expect(File).to exist @plumber.get_project_folder("new_project1")
      end

      it "returns path to archived project folder" do
        name = "archived project for get_project_folder"
        project = @plumber.new_project name
        expect(@plumber.get_project_folder(name)).to be_truthy
        expect(File).to exist @plumber.get_project_folder(name)

        expect(@plumber.archive_project(project)).to be_truthy
        expect(File).to exist @plumber.get_project_folder(name,:archive)
      end

    end

    describe described_class, "#get_project_file_path" do

      it "returns false for missing project" do
        expect(@plumber.get_project_file_path("nonexistent_project")).to be_falsey
      end

      it "returns path to project folder" do
        expect(@plumber.new_project("new_project1")).to be_truthy
        expect(@plumber.get_project_folder("new_project1")).to be_truthy
        expect(File).to exist @plumber.get_project_folder("new_project1")

        expect(File).to exist @plumber.get_project_file_path("new_project1")
      end

      it "finds files in the archive"
      #do
      #  name = "archived project"
      #  @plumber.new_project name
      #  @plumber.archive_project name
      #  expect(@plumber.get_project_file_path(name, :archive)).to be_truthy
      #  expect(File).to exist @plumber.get_project_file_path(name, :archive)
      #end

    end

    describe described_class, "#list_project_paths" do
      it "lists projects"
    #  do
    #    @plumber.list_project_paths).to be_falsey
    #  end
    end

    describe described_class, "#archive_project" do

      before :each do
        puts "before only runs in #archive_project"
      end
      it "moves project to archive" do
        name = "old_project"
        project = @plumber.new_project name
        expect(@plumber.archive_project(project)).to be_truthy
      end

      it "refuses to move non existent project to archive" do
        expect(@plumber.archive_project("nonexistent_project")).to be_falsey
      end

      it "moves project to archive, with special year" do
        project = @plumber.new_project "project_from_2010"
        expect(@plumber.archive_project(project, 2010)).to be_truthy
      end

      ## TODO uncertain about behaviour: repeating name, is prefix part of name?
      #it "moves project to archive, with special year and prefix" do
      #  name = "project_from_2010"
      #  project = @plumber.new_project name
      #  expect(@plumber.archive_project(name, 2010, "R025")).to be_truthy
      #end
    end

    describe described_class, "#unarchive_project" do

      it "moves project from archive to working_dir" do
        project = @plumber.new_project "reheated_project"
        expect(File).to exist project.path
        expect(@plumber.archive_project(project)).to be_truthy
        expect(@plumber.unarchive_project(project)).to be_truthy
      end

      it "moves project from archive to working_dir" do
        project = @plumber.new_project "old_project_from_2010"
        expect(@plumber.archive_project(project,2010)).to be_truthy
        expect(@plumber.unarchive_project(project,2010)).to be_truthy
      end

      it "refuses to move non existent project from archive to working_dir" do
        expect(@plumber.archive_project("nonexistent_project")).to be_falsey
      end

      it "refuses to overwrite project already in archive" do
        name = "previously archived"
        project = @plumber.new_project name
        expect(@plumber.archive_project(project)).to be_truthy
        project = @plumber.new_project name
        expect(@plumber.archive_project(project)).to be_falsey
      end

      it "refuses to overwrite project in working from archive" do
        name = "dont_overwrite me"
        project = @plumber.new_project name
        expect(@plumber.archive_project(project)).to be_truthy
        project = @plumber.new_project name
        expect(@plumber.unarchive_project(project)).to be_falsey
      end

    end

    #describe described_class, "#lookup" do

      it "looks up projects by name" # TODO also test look in archive
      it "looks up projects by index"
      it "looks up projects by unique beginning of name"

    #end

  end

  context "generally" do

    before :each do
      @plumber.new_project "listed project"
    end

    after :each do
      pp Dir.glob @plumber.dirs[:working]
      @plumber.new_project "listed project"
    end

    it "escapes space separated filenames" do
      name = "   space separated filename   "
      project = @plumber.new_project name
      expect(File).to exist project.path
      expect(@plumber.archive_project(project)).to be_truthy
      expect(@plumber.unarchive_project(project)).to be_truthy
      expect(@plumber.get_project_folder(name)).to be_truthy
      expect(@plumber.get_project_folder(name.strip)).to be_truthy
    end

    it "escapes dash separated filenames" do
      name = "dash/separated/filename"
      project = @plumber.new_project name
      expect(File).to exist project.path
      expect(@plumber.archive_project(project)).to be_truthy
      expect(@plumber.unarchive_project(project)).to be_truthy
      expect(@plumber.get_project_folder(name)).to be_truthy
    end

    it "escapes dot separated filenames" do
      name = "dot.separated.filename"
      project = @plumber.new_project name
      expect(File).to exist project.path
      expect(@plumber.archive_project(project)).to be_truthy
      expect(@plumber.unarchive_project(project)).to be_truthy
      expect(@plumber.get_project_folder(name)).to be_truthy
    end

  end

end
