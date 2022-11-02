# frozen_string_literal: true

module Ci
  module JobToken
    class InboundScope
      attr_reader :source_project

      def initialize(source_project)
        @source_project = source_project
      end

      def includes?(target_project)
        # if the flag is disabled any project is considered to be in scope.
        return true unless Feature.enabled?(:ci_inbound_job_token_scope, source_project)
        # if the setting is disabled any project is considered to be in scope.
        return true unless source_project.ci_inbound_job_token_scope_enabled?

        self_referential?(target_project) || added?(target_project)
      end

      def all_projects
        Project.from_union(target_projects, remove_duplicates: false)
      end

      private

      def self_referential?(target_project)
        target_project.id == source_project.id
      end

      def added?(target_project)
        Ci::JobToken::ProjectScopeLink
          .added_project(source_project, target_project)
          .inbound
          .exists?
      end

      def target_project_ids
        Ci::JobToken::ProjectScopeLink
          .from_project(source_project)
          .inbound
          .pluck(:target_project_id)
      end

      def target_projects
        [
          Project.id_in(source_project),
          Project.id_in(target_project_ids)
        ]
      end
    end
  end
end
