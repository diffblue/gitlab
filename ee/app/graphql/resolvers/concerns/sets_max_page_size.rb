# frozen_string_literal: true

module SetsMaxPageSize
  extend ActiveSupport::Concern

  DEPRECATED_MAX_PAGE_SIZE = 1000

  # We no longer need 1000 page size after epics roadmap pagination feature is released,
  # after :performance_roadmap flag rollout we can safely use default max page size(100)
  # for epics, child epics and child issues without breaking current roadmaps.
  #
  # When removing :performance_roadmap flag delete this file and remove its method call and
  # the fields using the resolver will keep using default max page size.
  # Flag rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/337198

  private

  def set_temp_limit_for(actor)
    max_page_size =
      if Feature.enabled?(:performance_roadmap, actor, default_enabled: :yaml)
        context.schema.default_max_page_size
      else
        DEPRECATED_MAX_PAGE_SIZE
      end

    field.max_page_size = max_page_size # rubocop: disable Graphql/Descriptions
  end
end
