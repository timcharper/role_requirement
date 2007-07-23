module RoleRequirement
  def self.included(klass)
    klass.send :include, RoleSecurityInstanceMethods
    klass.send :extend, RoleSecurityClassMethods
    klass.send :helper_method, :url_options_authenticate? 
  end
  
  module RoleSecurityClassMethods
    
    def reset_role_requirements!
      @role_requirements=nil
    end
    
    def require_role(roles, options = {})
      options.assert_valid_keys(:if, :only, :except)
      
      # only declare that before filter once
      unless (@before_filter_declared||=false)
        @before_filter_declared=true
        before_filter :check_roles
      end
      
      # convert to an array if it isn't already
      roles = [roles] unless Array===roles
      
      # convert any actions into symbols
      for key in [:only, :except]
        if options.has_key?(key)
          options[key] = [options[key]] unless Array === options[key]
          options[key] = options[key].collect{|v| v.to_sym}
        end 
      end
      
      @role_requirements||=[]
      @role_requirements << {:roles => roles, :options => options }
    end
    
    def user_authorized_for?(user, params = {}, binding = self.binding)
      return true unless Array===@role_requirements
      @role_requirements.each{| role_requirement|
        roles = role_requirement[:roles]
        options = role_requirement[:options]
        # do the options match the params?
        
        # check the action
        if options.has_key?(:only)
          next unless options[:only].include?( (params[:action]||"index").to_sym )
        end
        
        if options.has_key?(:except)
          next if options[:except].include?( (params[:action]||"index").to_sym)
        end
        
        if options.has_key?(:if)
          # execute the proc.  if the procedure returns false, we don't need to authenticate these roles
          next unless ( String===options[:if] ? eval(options[:if], binding) : options[:if].call(params) )
        end
        
        if options.has_key?(:unless)
          # execute the proc.  if the procedure returns true, we don't need to authenticate these roles
          next if ( String===options[:unless] ? eval(options[:unless], binding) : options[:unless].call(params) )
        end
        
        # check to see if they have one of the required roles
        passed = false
        roles.each{|role|
          passed = true if user && user.has_role?(role)
        }
        return false unless passed
      }
      
      return true
    end
  end
  
  module RoleSecurityInstanceMethods
    def check_roles       
      return access_denied unless self.class.user_authorized_for?(current_user, params, binding)
      
      true
    end
    
  protected
    # receives a :controller, :action => finds the controller and runs user_authorized_for?
    def url_options_authenticate?(params = {})
      params = params.symbolize_keys
      if params[:controller]
        # find the controller class
        klass = eval("#{params[:controller]}_controller".classify)
      else
        klass = self.class
      end
      klass.user_authorized_for?(current_user, params, binding)
    end
  end
end