# frozen_string_literal: true

module EE
  module Gitlab
    module ImportSources
      extend ::Gitlab::Utils::Override

      override :import_table
      def import_table
        super + ee_import_table
      end

      def ee_import_table
        # This method can be called/loaded before the database
        # has been created. With this guard clause we prevent querying
        # the License table until the table exists
        return [] unless ::Gitlab::Database.main.cached_table_exists?('licenses') &&
          License.feature_available?(:custom_project_templates)

        [::Gitlab::ImportSources::ImportSource.new('gitlab_custom_project_template',
                                                   'GitLab custom project template export',
                                                   ::Gitlab::ImportExport::Importer)]
      end
    end
  end
end
