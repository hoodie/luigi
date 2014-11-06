require File.join File.dirname(__FILE__), "./lib/Luigi.rb"
require File.join File.dirname(__FILE__), "./lib/PlumberProject"


settings = {
  "dirs" => {
    "storage" => "caterings",
    "working" => "working",
    "archive" => "archive",
  },

  "templates_path" => nil, # defaults to scriptpath/templates
  "templates" => {
    "project" => "black.yml.erb"
  },

  # this API is not yet implemented
  "project_class" => PlumberProject
}

plumber = Luigi.new settings
