module Para
  class ResourceGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    argument :component_name, type: :string
    argument :attributes, type: :array

    desc 'Para resource generator'

    def welcome
      say 'Creating resource...'
    end

    def copy_resource_controller
      template 'resource_controller.rb', "app/controllers/admin/#{ plural_file_name }_controller.rb"
    end

    def add_resource_to_component_controller
      gsub_file "app/controllers/admin/#{ component_name.singularize }_component_controller.rb", /# You can access @component here/ do
        <<-RUBY
          @q = @component.#{ plural_file_name }.search params[:q]
          @resources = @q.result.page(params[:page]).per(10)
        RUBY
      end
    end
    def insert_route
      inject_into_file 'config/routes.rb', after: "component :#{ component_name.underscore } do" do
        "\n      resources :#{ plural_file_name }"
      end
    end

    def insert_relation_to_show
      inject_into_file "app/views/admin/#{ component_name.underscore }_component/show.html.haml", after: '%h1.page-header= @component.name' do
        "\n\n= render partial: find_partial_for(:#{ plural_file_name }, :table), locals: { resources: @resources, relation: :#{ plural_file_name } }"
      end
    end

    def generate_model
      generate 'model',
        file_name,
        attributes.map { |attr|
          "#{ attr.name }:#{ attr.type }"
        }.insert(-1, 'component:references').join(' ')
    end

    def migrate
      rake 'db:migrate'
    end

    def insert_belongs_to_to_resource
      inject_into_file "app/models/#{ file_name }.rb", after: "belongs_to :component" do
        ", class_name: 'Para::Component::Base'"
      end
    end

    def insert_has_many_to_component
      inject_into_file "app/models/para/component/#{ component_name.underscore }.rb", after: "register :#{ component_name.underscore }, self" do
        "\n\n      has_many :#{ plural_file_name }, class_name: '::#{ class_name }', inverse_of: :component,
          foreign_key: :component_id, dependent: :destroy"
      end
    end
  end
end