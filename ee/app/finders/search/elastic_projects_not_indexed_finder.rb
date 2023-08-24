# frozen_string_literal: true

# For finding projects with repository data missing from the index
module Search
  class ElasticProjectsNotIndexedFinder
    def self.execute
      new.execute
    end

    def execute
      raise 'This cannot be run on GitLab.com' if Gitlab.com?

      elastic_enabled_projects.not_indexed_in_elasticsearch
    end

    private

    def elastic_enabled_projects
      return Project.all unless ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

      ::Gitlab::CurrentSettings.elasticsearch_limited_projects
    end
  end
end
