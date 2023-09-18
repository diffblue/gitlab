# frozen_string_literal: true

module Resolvers
  module MemberRoles
    class PermissionListResolver < BaseResolver
      type Types::MemberRoles::CustomizablePermissionType, null: true

      def resolve
        MemberRole::ALL_CUSTOMIZABLE_PERMISSIONS.map do |permission, definition|
          definition.merge(value: permission)
        end
      end
    end
  end
end
