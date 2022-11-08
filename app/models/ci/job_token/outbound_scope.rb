# frozen_string_literal: true

module Ci
  module JobToken
    class OutboundScope
      def initialize(source_project)
        @source_project = source_project
      end

      def includes?(target_project)
        # if the setting is disabled any project is considered to be in scope.
        return true unless @source_project.ci_outbound_job_token_scope_enabled?

        allowlist.includes?(target_project)
      end

      delegate :all_projects, to: :allowlist

      private

      def allowlist
        Ci::JobToken::Allowlist.new(@source_project, direction: :outbound)
      end
    end
  end
end
