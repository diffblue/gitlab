# frozen_string_literal: true

module Resolvers
  module Ci
    class AllJobsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      type ::Types::Ci::JobType.connection_type, null: true

      argument :statuses, [::Types::Ci::JobStatusEnum],
              required: false,
              description: 'Filter jobs by status.'

      def resolve_with_lookahead(statuses: nil)
        jobs = ::Ci::JobsFinder.new(current_user: current_user, params: { scope: statuses }).execute

        apply_lookahead(jobs)
      end
    end
  end
end
