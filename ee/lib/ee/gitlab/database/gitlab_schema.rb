# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      module GitlabSchema
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :dictionary_path_globs
          def dictionary_path_globs
            super + Gitlab::Database::EE_DATABASES_NAME_TO_DIR.map do |_, ee_db_dir|
                      Rails.root.join(ee_db_dir, 'docs', '*.yml')
                    end
          end

          override :view_path_globs
          def view_path_globs
            super + Gitlab::Database::EE_DATABASES_NAME_TO_DIR.map do |_, ee_db_dir|
                      Rails.root.join(ee_db_dir, 'docs', 'views', '*.yml')
                    end
          end

          override :deleted_tables_path_globs
          def deleted_tables_path_globs
            super + Gitlab::Database::EE_DATABASES_NAME_TO_DIR.map do |_, ee_db_dir|
                      Rails.root.join(ee_db_dir, 'docs', 'deleted_tables', '*.yml')
                    end
          end

          override :deleted_views_path_globs
          def deleted_views_path_globs
            super + Gitlab::Database::EE_DATABASES_NAME_TO_DIR.map do |_, ee_db_dir|
                      Rails.root.join(ee_db_dir, 'docs', 'deleted_views', '*.yml')
                    end
          end
        end
      end
    end
  end
end
