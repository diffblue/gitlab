# frozen_string_literal: true

module EE
  module ProjectWiki
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :after_wiki_activity
    def after_wiki_activity
      super

      project.repository_state&.touch(:last_wiki_updated_at)
    end

    # TODO: This method may be removed once we implement Group Wikis
    class_methods do
      extend ::Gitlab::Utils::Override

      override :use_separate_indices?
      def use_separate_indices?
        ::Elastic::DataMigrationService.migration_has_finished?(:migrate_wikis_to_separate_index)
      end
    end
  end
end
