# Role authentication system

require "role_requirement_system.rb"
if RAILS_ENV=="test"
  require "role_requirement_test_helper.rb"
  require "hijacker.rb"
  Test::Unit::TestCase.send :include, RoleRequirementTestHelper
end

ActionController::Base.send :include, RoleRequirement