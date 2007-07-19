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