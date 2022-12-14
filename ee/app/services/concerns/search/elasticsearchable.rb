# frozen_string_literal: true

module Search
  module Elasticsearchable
    SCOPES_ONLY_BASIC_SEARCH = %w(epics).freeze

    def use_elasticsearch?
      return false if params[:basic_search]
      return false if SCOPES_ONLY_BASIC_SEARCH.include?(params[:scope])
      return false unless advanced_user_search?

      ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: elasticsearchable_scope)
    end

    def elasticsearchable_scope
      raise NotImplementedError
    end

    def advanced_user_search?
      return true unless params[:scope] == 'users'
      return false if params[:project_id] || params[:group_id]
      return false unless ::Feature.enabled?(:advanced_user_search, current_user, type: :ops)

      ::Elastic::DataMigrationService.migration_has_finished?(:create_user_index) &&
        ::Elastic::DataMigrationService.migration_has_finished?(:backfill_users)
    end
  end
end
