class RolesGenerator < Rails::Generator::NamedBase
  attr_accessor :roles_model_name, 
    :roles_table_name, 
    :users_table_name, 
    :users_model_name
  
  def initialize(runtime_args, runtime_options = {})
    super
    @roles_model_name = (runtime_args[0] || "Role").classify
    @users_model_name = (runtime_args[1] || "User").classify
    
    @roles_table_name = @roles_model_name.tableize
    @users_table_name = @users_model_name.tableize
    
    puts "Generating #{@roles_model_name} against #{@users_model_name}"
    
    
  end  
  
  def manifest
    record do |m|

      unless options[:skip_migration]
        m.migration_template 'roles_migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{roles_model_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{roles_table_name}"
      end
      
      # modify the User model unless it's already got RoleRequirement code in there
      
      users_model_content = File.read(users_model_filename)
      
      # already have the function?  Don't generate it twice
      unless users_model_content.include?("def has_role?")
        # find the line that has the model declaration
        lines = users_model_content.split("\n")
        found_line = nil
        
        regexp = Regexp.new("Class +#{users_model_name}")
        0.upto(lines.length-1) {|line_number| 
          found_line = line_number if regexp.match(lines[line_number])
        }
        if found_line
          puts found_line

          # insert the rest of these lines after the found line
          content_for_insertion = render_template("_user_functions.erb")
          lines.insert(found_line+1, content_for_insertion)
          users_model_content = lines * "\n"
          
          File.open(users_model_filename, "w") {|f| f.puts users_model_content }
          
        end
        
      end
      
      
    end
  end
  
  def render_template(name)
    template = File.read( File.join( File.dirname(__FILE__), name))
    ERB.new(template, nil, "-").result(binding)
  end
  
  def habtm_name;       [roles_table_name, users_table_name].sort * "_"; end
  def roles_foreign_key; roles_table_name.singularize.foreign_key; end
  def users_foreign_key; users_table_name.singularize.foreign_key; end
  def users_model_filename;  "#{RAILS_ROOT}/app/models/#{users_model_name.underscore}.rb"; end;
  
  protected
    def banner
      "Usage: #{$0} roles RoleModelName [TargetUserModelName]"
    end

end