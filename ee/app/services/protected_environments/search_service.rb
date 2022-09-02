# frozen_string_literal: true
module ProtectedEnvironments
  class SearchService < ::ProtectedEnvironments::BaseService
    # Returns unprotected environments filtered by name
    # Limited to 20 per performance reasons
    # rubocop: disable CodeReuse/ActiveRecord
    def execute(name)
      raise NotImplementedError unless project_container?

      container
        .environments
        .where.not(name: container.protected_environments.select(:name))
        .for_name_like(name, limit: nil)
        .order_by_last_deployed_at
        .limit(20)
        .pluck(:name)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
