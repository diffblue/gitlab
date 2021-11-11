# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      class ByIdsFinder
        include ::Integrations::ReactivelyCached

        self.reactive_cache_key = ->(finder) { [finder.model_name] }
        self.reactive_cache_work_type = :external_dependency
        self.reactive_cache_worker_finder = ->(_id, *cache_args) { from_cache(*cache_args) }

        attr_reader :project, :jira_issue_ids

        def self.from_cache(project_id, jira_issue_ids)
          project = Project.find(project_id)

          new(project, jira_issue_ids)
        end

        def initialize(project, jira_issue_ids)
          @project = project
          @jira_issue_ids = jira_issue_ids
        end

        def execute
          with_reactive_cache(*cache_args) { |issues| issues }
        end

        def calculate_reactive_cache(*)
          # rubocop: disable CodeReuse/Finder
          ::Projects::Integrations::Jira::IssuesFinder
            .new(project, issue_ids: jira_issue_ids)
            .execute
            .then { |issues| { issues: issues, error: nil } }
        rescue ::Projects::Integrations::Jira::IssuesFinder::IntegrationError, ::Projects::Integrations::Jira::IssuesFinder::RequestError => error
          { issues: [], error: error.message }
          # rubocop: enable CodeReuse/Finder
        end

        def clear_cache!
          clear_reactive_cache!(*cache_args)
        end

        def model_name
          self.class.name.underscore.tr('/', '_')
        end

        def cache_args
          [project.id, jira_issue_ids]
        end

        private

        def id
          nil
        end
      end
    end
  end
end
