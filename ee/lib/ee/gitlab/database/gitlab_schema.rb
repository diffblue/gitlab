# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      module GitlabSchema
        extend ActiveSupport::Concern

        EE_GITLAB_SCHEMAS_FILE = 'ee/lib/ee/gitlab/database/gitlab_schemas.yml'

        class_methods do
          extend ::Gitlab::Utils::Override

          override :tables_to_schema
          def tables_to_schema
            @tables_to_schema ||= super.merge(ee_tables_to_schema)
          end

          def ee_tables_to_schema
            @ee_tables_to_schema ||= YAML.load_file(Rails.root.join(EE_GITLAB_SCHEMAS_FILE))
          end
        end
      end
    end
  end
end
