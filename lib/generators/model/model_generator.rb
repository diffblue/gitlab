# frozen_string_literal: true

require 'rails/generators/active_record/model/model_generator'

module Model
  class ModelGenerator < ActiveRecord::Generators::ModelGenerator
    def create_migration_file
      return if skip_migration_creation?

      if options[:indexes] == false
        attributes.each { |a| a.attr_options.delete(:index) if a.reference? && !a.has_index? }
      end

      migration_template "../../active_record/migration/create_table_migration.rb",
                         File.join(db_migrate_path, "a_create_#{table_name}.rb")
    end

    # Override to find templates from superclass as well
    def source_paths
      super + [self.class.superclass.default_source_root]
    end
  end
end
