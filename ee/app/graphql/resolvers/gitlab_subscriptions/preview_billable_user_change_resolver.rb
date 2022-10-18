# frozen_string_literal: true

module Resolvers
  module GitlabSubscriptions
    class PreviewBillableUserChangeResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::GitlabSubscriptions::PreviewBillableUserChangeType, null: true

      argument :add_group_id, GraphQL::Types::Int, required: false, description: 'Group ID to add.'
      argument :add_user_emails, [GraphQL::Types::String], required: false, description: 'User emails to add.'
      argument :add_user_ids, [GraphQL::Types::Int], required: false, description: 'User IDs to add.'
      argument :role, Types::GitlabSubscriptions::UserRoleEnum, required: true,
                                                                description: 'Role of users being added to group.'

      def resolve(**args)
        authorize!

        result = ::GitlabSubscriptions::PreviewBillableUserChangeService.new(
          current_user: current_user,
          target_namespace: top_level_namespace,
          **args
        ).execute

        raise GraphQL::ExecutionError, result[:error] unless result[:success]

        result[:data]
      end

      def ready?(**args)
        if args.values_at(:add_user_ids, :add_user_emails, :add_group_id).compact.blank?
          raise Gitlab::Graphql::Errors::ArgumentError,
            'Must provide "addUserIds", "addUserEmails" or "addGroupId" argument'
        end

        super
      end

      private

      def authorize!
        return if Ability.allowed?(current_user, :read_billable_member, top_level_namespace)

        raise_resource_not_available_error!
      end

      def top_level_namespace
        @top_level_namespace ||= object.root_ancestor
      end
    end
  end
end
