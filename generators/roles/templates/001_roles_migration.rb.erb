class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table "<%= roles_table_name %>" do |t|
      t.column :name, :string
    end
    
    # generate the join table
    create_table "<%= habtm_name %>", :id => false do |t|
      t.column "<%= roles_foreign_key %>", :integer
      t.column "<%= users_foreign_key %>", :integer
    end
    add_index "<%= habtm_name %>", "<%= roles_foreign_key %>"
    add_index "<%= habtm_name %>", "<%= users_foreign_key %>"
  end

  def self.down
    drop_table "<%= roles_table_name %>"
    drop_table "<%= habtm_name %>"
  end
end