# frozen_string_literal: true

module EE
  module Wiki
    extend ActiveSupport::Concern
    prepended do
      include Elastic::WikiRepositoriesSearch
    end

    # No need to have a Kerberos Web url. Kerberos URL will be used only to
    # clone
    def kerberos_url_to_repo
      [::Gitlab.config.build_gitlab_kerberos_url, '/', full_path, '.git'].join('')
    end

    class_methods do
      extend ::Gitlab::Utils::Override
      def base_class
        ::Wiki
      end

      def use_separate_indices?
        ::Elastic::DataMigrationService.migration_has_finished?(:migrate_wikis_to_separate_index)
      end
    end
  end
end
