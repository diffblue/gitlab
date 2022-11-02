# frozen_string_literal: true

# This model represents the surface where a CI_JOB_TOKEN can be used.
#
# A scope is initialized with a source project.
#
# Projects can be added to the scope by adding ScopeLinks to
# create an allowlist of projects.
#
# Projects in the outbound allowlist can be accessed via the token
# in the source project.
#
# Projects in the inbound allowlist can use their token to access
# the source project.
#
# CI_JOB_TOKEN should be considered untrusted without these features enabled.
#

module Ci
  module JobToken
    class Scope
      attr_reader :source_project

      def initialize(source_project)
        @source_project = source_project
      end

      def includes?(target_project)
        outbound_scope.includes?(target_project)
      end

      def all_projects
        outbound_scope.all_projects
      end

      private

      def outbound_scope
        Ci::JobToken::OutboundScope.new(source_project)
      end

      # TODO(https://gitlab.com/gitlab-org/gitlab/-/issues/346298): Use in this class
      def inbound_scope
        Ci::JobToken::InboundScope.new(source_project)
      end
    end
  end
end
