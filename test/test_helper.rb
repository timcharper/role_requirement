require 'test/unit'
require "rubygems"
require 'active_support'
require "erb"
require "ostruct"
# render the RoleRequirementSystem template and "eval it"

def render_template_with_locals(abs_name, locals = {})
  template = File.read(File.join( abs_name) )
  ERB.new(template, nil, "-").result(OpenStruct.new(locals).send(:binding))
end

def include_rendered_template(abs_name, locals = {})
  code = render_template_with_locals(abs_name, locals)
  eval code, binding, abs_name, 1
end

puts include_rendered_template(
  File.join( File.dirname(__FILE__), "../generators/shared_templates", "role_requirement_system.rb.erb"), 
  {:users_name => "user" }
)

for file in ["authenticated_system", "controller_stub.rb", "user_stub.rb"]
  require File.expand_path(File.join(File.dirname(__FILE__), file))
end



def dbg
  require 'ruby-debug'
  Debugger.start
  debugger
end
