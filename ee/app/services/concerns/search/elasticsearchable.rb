# frozen_string_literal: true

module Search
  module Elasticsearchable
    SCOPES_ADVANCED_SEARCH_ALWAYS_ENABLED = %w[users].freeze

    def use_elasticsearch?
      return false if params[:basic_search]
      return false unless advanced_epic_search?

      ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: elasticsearchable_scope)
    end

    def elasticsearchable_scope
      raise NotImplementedError
    end

    def global_elasticsearchable_scope?
      SCOPES_ADVANCED_SEARCH_ALWAYS_ENABLED.include?(params[:scope])
    end

    def advanced_epic_search?
      return true unless params[:scope] == 'epics'
      return false unless ::Feature.enabled?(:advanced_epic_search, current_user)

      ::Elastic::DataMigrationService.migration_has_finished?(:create_epic_index) &&
        ::Elastic::DataMigrationService.migration_has_finished?(:backfill_epics)
    end
  end
end
