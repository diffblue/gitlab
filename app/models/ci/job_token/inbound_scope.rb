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

        allowlist.includes?(target_project)
      end

      def all_projects
        allowlist.all_projects
      end

      private

      def allowlist
        Ci::JobToken::Allowlist.new(source_project, direction: :inbound)
      end
    end
  end
end
