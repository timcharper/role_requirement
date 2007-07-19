require File.join(File.dirname(__FILE__), '../test_helper.rb')

class MyController < ControllerStub 
  include RoleRequirement
end

class OtherController < ControllerStub
  include RoleRequirement
end

class TestRoleController < Test::Unit::TestCase
  def setup
    MyController.reset_role_requirements!
    OtherController.reset_role_requirements!
    
    @controller = MyController.new
  end
  
  def test__required_role_for_all__should_require
    @controller.class.require_role "admin"
    @controller.current_user = User.new(:roles => "")
    
    assert(!@controller.check_roles)

    @controller.current_user = User.new(:roles => "admin")
    assert(@controller.check_roles)
  end
  
  def test_required_role_for_some_actions_only__should_require
    @controller.class.require_role "admin", :only => [:update, :destroy, :delete]
    @controller.current_user = User.new(:roles => "")
    
    @controller.params = {:action => "update" }
    assert(!@controller.check_roles, "shouldn't pass")
    
    @controller.params = {:action => "index" }
    assert(@controller.check_roles, "should pass")
  end
  
  def test_required_role_for_excluded_actions_only__should_require
    @controller.class.require_role "admin", :except => :index
    @controller.current_user = User.new(:roles => "")
    
    @controller.params = {:action => "update" }
    assert(!@controller.check_roles, "shouldn't pass")
    
    @controller.params = {:action => "index" }
    assert(@controller.check_roles, "should pass")
  end
  
  def test__no_user__role_required__returns_false
    @controller.class.require_role "admin"
    @controller.current_user = nil
    
    @controller.params = {:action => "destroy" }
    assert(!@controller.check_roles, "shouldnt pass")
  end
  
  def test__no_user__role_not_required__returns_true
    @controller.class.require_role "admin", :except => :index
    @controller.current_user = nil
    
    @controller.params = {:action => "index" }
    assert(@controller.check_roles, "should pass")
  end
  
  
  def test_required_role_for_if_proc__should_require
    @controller.class.require_role "admin", :only => :list, :if => Proc.new {|params| params[:status] == "completed" }
    @controller.current_user = User.new(:roles => "")
    
    @controller.params = {:action => "list", :status => "pending" }
    assert(@controller.check_roles, "should pass")
    
    @controller.params = {:action => "list", :status => "completed" }
    assert(!@controller.check_roles, "shouldn't pass")
  end
  
  def test__controllers_dont_share_requirements
    @controller2 = OtherController.new
    @controller2.class.require_role "user"
    @controller2.current_user = User.new(:roles => "user")
    
    @controller.class.require_role "admin"
    @controller.current_user = User.new(:roles => "admin")

    assert(@controller.check_roles, "should pass")
    assert(@controller2.check_roles, "should pass")

    @controller2.current_user = User.new(:roles => "")
    @controller.current_user = User.new(:roles => "")

    assert(!@controller.check_roles, "shouldn't pass")
    assert(!@controller2.check_roles, "shouldn't pass")
  end
  
  def test__url_options_authenticate
    MyController.require_role "admin", :only => :destroy
    OtherController.require_role "admin", :only => :destroy
    
    @controller.current_user = User.new(:roles => "")
    
    assert ! @controller.send(:url_options_authenticate?, { :controller => :my, :action => "destroy" } ), "shouldn't pass"
    assert ! @controller.send(:url_options_authenticate?, { :controller => :other, :action => "destroy" } ), "shouldn't pass"
    
    assert @controller.send(:url_options_authenticate?, { :controller => :my, :action => "index" } ), "should pass"
    assert @controller.send(:url_options_authenticate?, { :controller => :other, :action => "index" } ), "should pass"
  end
  
  def test__url_options_authenticate__nil_value__should_handle
    assert_nothing_raised do
      @controller.send(:url_options_authenticate?, { :controller => :my } )
    end
  end
  
  def test__url_options_authenticate__nil_value__should_treat_as_index
    MyController.require_role "admin", :only => :index
    @controller.current_user = User.new(:roles => "")

    assert ! @controller.send(:url_options_authenticate?, { :controller => :my } ), "shouldn't pass"
    assert @controller.send(:url_options_authenticate?, { :controller => :my, :action => "destroy" } ), "should pass"
  end
  
  def test__url_options_authenticate__no_controller__assumes_self
    MyController.require_role "admin", :only => :index
    @controller.current_user = User.new(:roles => "")

    assert ! @controller.send(:url_options_authenticate?, { :action => "index" } ), "shouldn't pass"
    assert @controller.send(:url_options_authenticate?, { :action => "boogy" } ), "shouldn't pass"
  
  end
end