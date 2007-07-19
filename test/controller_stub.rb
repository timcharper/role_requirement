class ControllerStub
  
  attr_accessor :params
  attr_accessor :current_user 
  
  def self.before_filter(*args)
  end

  def self.helper_method(*args)
  end
  
  def access_denied
    false
  end
end