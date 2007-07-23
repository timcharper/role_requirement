# Hijacker class
#
# This class is used by RoleRequirementTestHelper to temporarily hijack a controller action for testing
#
# It can be used for other tests as well.
#
# You can contract the author with questions
#   Tim C. Harper - irb(main):001:0> ( 'tim_see_harperATgmail._see_om'.gsub('_see_', 'c').gsub('AT', '@') )
#
#
# Example usage:
#   hijacker = Hijacker.new(ListingsController)
#   hijacker.hijack_instance_method("index", "render :text => 'hello world!'" )
#   get :index        # will return "hello world"
#   hijacker.restore  # put things back the way you found it

class Hijacker
  def initialize(klass)
    @target_klass = klass
    @store = []
  end
  
  def hijack_instance_method(method_name, eval_string = nil, arg_names = [], &block)
    method_name = method_name.to_s
    # You have got love ruby!  What other language allows you to pillage and plunder a class like this? 
    @store << [
      method_name, 
      @target_klass.instance_methods.include?(method_name) && @target_klass.instance_method(method_name)
    ]
    
    @target_klass.send :undef_method, method_name
    if Symbol === eval_string
      @target_klass.send :define_method, method_name, @target_klass.instance_methods(eval_string)
    elsif String === eval_string
      @target_klass.class_eval <<-EOF 
        def #{method_name}(#{arg_names * ','})
          #{eval_string}
        end
      EOF
    elsif block_given?
      @target_klass.send :define_method, method_name, block
    end
    
    true
  rescue
    false
  end
  
  # restore all 
  def restore
    @store.reverse_each{ |method_name, method| 
      @target_klass.send :undef_method, method_name
      @target_klass.send :define_method, method_name, method if method
    }
    @store.clear
    true
  rescue
    false
  end
end