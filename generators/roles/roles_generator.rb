require( File.join( File.dirname(__FILE__), "../role_generator_helpers" ))

class RolesGenerator < Rails::Generator::NamedBase
  
  include RoleGeneratorHelpers
  
  attr_accessor :roles_model_name, 
    :roles_table_name, 
    :users_table_name, 
    :users_model_name,
    :next_user_id
  
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
      skip_fixtures = false
      # generate fixtures
      if (File.exists?(users_fixture_filename))
        users_fixtures_content = File.read users_fixture_filename
        users_fixtures = YAML.load(users_fixtures_content)
        
        begin
          throw "Can't understand whatever is in #{users_fixture_filename}" unless Hash===users_fixtures
          
          unless users_fixtures.has_key?("admin")
            @next_user_id = (users_fixtures.collect{ |k, params| params["id"].to_i}.max||0) + 1
            output = users_fixtures_content + "\n" + render_template("users_admin_fixture_with_roles.yml")
            
            # prevent generator from truncating the whole file if something goes wrong.
            if output.length > users_fixtures_content.length
              File.open(users_fixture_filename, "w") {|f| f.write(output) }
            end
          else
            @next_user_id = users_fixtures["admin"]["id"].to_i
          end
        rescue e
          puts e.message
          skip_fixtures = true
        end
      else
        # users.yml doesn't exist.  Generate it from scratch
        @next_user_id = 1
        
        m.template 'users_admin_fixture_with_roles.yml',
          File.join('test/fixtures', "#{users_table_name}.yml")
      end
      
      unless skip_fixtures
        # generate roles and users_roles
        m.template 'roles_users.yml',
                  File.join('test/fixtures', "#{habtm_name}.yml")
        m.template 'roles.yml',
                  File.join('test/fixtures', "#{roles_table_name}.yml")
      end
      
      content_for_insertion = render_template("_user_functions.erb")
      # modify the User model unless it's already got RoleRequirement code in there
      if insert_content_after(users_model_filename,
                        Regexp.new("class +#{users_model_name}"),
                        content_for_insertion,
                        :unless => lambda { |content| content.include? "def has_role?"; }
                        )
        puts "Added the following to the top of #{users_model_filename}:\n#{content_for_insertion}"
      else
        puts "Not modifying #{users_model_filename} because it appears that the funtion has_role? already exists."
      end
      
      # add the Role model
      m.template 'role_model.rb', roles_model_filename
      # generate migration
      unless options[:skip_migration]
        m.migration_template 'roles_migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{roles_model_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{roles_table_name}"
      end
      
      add_dependencies_to_application_rb
      
    end
  end
  
  def render_template(name)
    template = File.read( File.join( File.dirname(__FILE__), "templates", name))
    ERB.new(template, nil, "-").result(binding)
  end
  
  def habtm_name;       [roles_table_name, users_table_name].sort * "_"; end
  def roles_foreign_key; roles_table_name.singularize.foreign_key; end
  def roles_model_filename;  "#{RAILS_ROOT}/app/models/#{roles_model_name.underscore}.rb"; end;
  def users_foreign_key; users_table_name.singularize.foreign_key; end
  def users_model_filename;  "#{RAILS_ROOT}/app/models/#{users_model_name.underscore}.rb"; end;
  def users_fixture_filename;   "#{RAILS_ROOT}/test/fixtures/users.yml"; end;
  protected
    def banner
      "Usage: #{$0} roles RoleModelName [TargetUserModelName]"
    end

end