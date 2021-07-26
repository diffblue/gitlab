# frozen_string_literal: true

module Mutations
  module Issues
    class SetWeight < ::Mutations::Issues::Base
      graphql_name 'IssueSetWeight'

      argument :weight,
               GraphQL::Types::Int,
               required: false,
               description: 'The desired weight for the issue. ' \
               'If set to null, weight is removed.'

      def ready?(**args)
        unless args.key?(:weight)
          raise Gitlab::Graphql::Errors::ArgumentError, 'The `weight` argument is required (`null` accepted).'
        end

        super
      end

      def resolve(project_path:, iid:, weight:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        ::Issues::UpdateService.new(project: project, current_user: current_user, params: { weight: weight })
          .execute(issue)

        {
          issue: issue,
          errors: issue.errors.full_messages
        }
      end
    end
  end
end
