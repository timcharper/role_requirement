require 'test/unit'
require "rubygems"
require 'active_support'

for file in ["../lib/role_requirement_system.rb", "controller_stub.rb", "user_stub.rb"]
  require File.expand_path(File.join(File.dirname(__FILE__), file))
end



def dbg
  require 'ruby-debug'
  Debugger.start
  debugger
end
