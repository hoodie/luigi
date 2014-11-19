# encoding: utf-8
require 'fileutils'
require 'logger'
require 'hashr'

require File.join File.dirname(__FILE__), "luigi"
require File.join File.dirname(__FILE__), "luigi_project"

class LuigiProjectsList < Array


  def lookup_by_anything thing, value
    project_class = self[0].class
    raise "#{project_class} does not implement #{thing.to_s}()" unless project_class.instance_methods.include? thing
    raise "#{thing}" unless [:name, :date, :index].include? thing

    selection = self.map{|project| 
      project if project.method(thing).call.to_s.downcase.include? value.to_s.downcase
    }
    selection.select{|p|p}

  end

  def lookup_by_index index
    self.lookup_by_anything :index, index
  end

  def lookup_by_date date
    self.lookup_by_anything :date, date
  end

  def lookup_by_name name
    self.lookup_by_anything :name, name
  end

end
