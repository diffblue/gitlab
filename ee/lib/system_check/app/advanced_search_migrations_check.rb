# frozen_string_literal: true

module SystemCheck
  module App
    class AdvancedSearchMigrationsCheck < SystemCheck::BaseCheck
      set_name 'All migrations must be finished before doing a major upgrade'
      set_skip_reason 'skipped (Advanced Search is disabled)'
      set_check_pass -> { 'yes' }
      set_check_fail -> { fail_info }

      def skip?
        !Gitlab::CurrentSettings.current_application_settings.elasticsearch_indexing?
      end

      def check?
        !::Elastic::DataMigrationService.pending_migrations?
      end

      def show_error
        for_more_information('https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch.html#all-migrations-must-be-finished-before-doing-a-major-upgrade')
        try_fixing_it(
          'Wait for all advanced search migrations to complete.',
          'To list pending migrations, run `sudo gitlab-rake gitlab:elastic:list_pending_migrations`'
        )
      end

      def self.fail_info
        "no (You have #{pending_migrations_count} pending #{'migration'.pluralize(pending_migrations_count)}.)"
      end

      def self.pending_migrations_count
        ::Elastic::DataMigrationService.pending_migrations&.size || 0
      end
    end
  end
end
