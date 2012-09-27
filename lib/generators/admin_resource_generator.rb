class AdminResourceGenerator < Rails::Generators::Base
  argument :resource, type: :string
  
  def create_controller_file
    create_file "app/controllers/admin/#{resource.underscore.pluralize}_controller.rb", 
                "class Admin::#{resource.camelize.pluralize}Controller < Admin::ResourceController\n" \
                "end\n"
  end
  
  def add_method_to_model
    inject_into_class "app/models/#{resource.underscore.singularize}.rb", resource.singularize.camelize.constantize, 
                      "  administrate\n"
  end

  def create_view_directory
    empty_directory "app/views/admin/#{resource.underscore.pluralize}/"
  end
  
  def add_resource_to_routes
    insert_into_file "config/routes.rb", 
                     "      resources :#{resource.underscore.pluralize}\n", 
                     after: "## -- AdminResource -- ##\n"
  end
  
  def create_test_files
    create_file "spec/controllers/admin/#{resource.underscore.pluralize}_controller_spec.rb", 
                "require \"spec_helper\"\n\n" \
                "describe Admin::#{resource.camelize.pluralize}Controller do\n" \
                "  pending \"Generated by AdminResource\"\n" \
                "end\n"
                
    create_file "spec/requests/admin/manage_#{resource.underscore.pluralize}_spec.rb", 
                "require \"spec_helper\"\n\n" \
                "describe #{resource.camelize.singularize} do\n" \
                "  it_behaves_like \"managed resource\"\n" \
                "end\n"
  end
end
