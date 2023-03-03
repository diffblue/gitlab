# frozen_string_literal: true

module Search
  module Elasticsearchable
    SCOPES_ONLY_BASIC_SEARCH = %w(epics).freeze
    SCOPES_ADVANCED_SEARCH_ALWAYS_ENABLED = %w[users].freeze

    def use_elasticsearch?
      return false if params[:basic_search]
      return false if SCOPES_ONLY_BASIC_SEARCH.include?(params[:scope])
      return false if user_search? && !user_index_exists?

      ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: elasticsearchable_scope)
    end

    def elasticsearchable_scope
      raise NotImplementedError
    end

    def global_elasticsearchable_scope?
      SCOPES_ADVANCED_SEARCH_ALWAYS_ENABLED.include?(params[:scope])
    end

    private

    def user_search?
      params[:scope] == 'users'
    end

    def user_index_exists?
      ::Elastic::DataMigrationService.migration_has_finished?(:create_user_index) &&
        ::Elastic::DataMigrationService.migration_has_finished?(:backfill_users)
    end
  end
end
