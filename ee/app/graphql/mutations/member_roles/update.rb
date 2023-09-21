# frozen_string_literal: true

module Mutations
  module MemberRoles
    class Update < Base
      graphql_name 'MemberRoleUpdate'

      authorize :admin_group_member

      argument :description,
        GraphQL::Types::String,
        required: false,
        description: 'Description of the member role.'
      argument :id, ::Types::GlobalIDType[::MemberRole],
        required: true,
        description: 'ID of the member role to mutate.'
      argument :name,
        GraphQL::Types::String,
        required: false,
        description: 'Name of the member role.'

      def ready?(**args)
        if args.except(:id).blank?
          raise Gitlab::Graphql::Errors::ArgumentError, 'The list of member_role attributes is empty'
        end

        super
      end

      def resolve(**args)
        member_role = authorized_find!(id: args.delete(:id))

        response = ::MemberRoles::UpdateService.new(member_role.namespace, current_user, args).execute(member_role)

        {
          member_role: response.payload[:member_role],
          errors: response.errors
        }
      end
    end
  end
end
