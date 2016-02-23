# encoding: utf-8
require 'fileutils'
require 'logger'
require 'hashr'

require File.join File.dirname(__FILE__), "luigi"
require File.join File.dirname(__FILE__), "luigi_project"

class LuigiProjectsList < Array


  def lookup_by_anything thing, value
    raise "#{thing}" unless [:name, :date, :index].include? thing

    selection = self.map{|project|
      if project.instance_methods.includes? thing  and project.method(thing).call.to_s.downcase.include? value.to_s.downcase
        project
      end
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
