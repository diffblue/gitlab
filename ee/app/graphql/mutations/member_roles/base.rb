# frozen_string_literal: true

module Mutations
  module MemberRoles
    class Base < ::Mutations::BaseMutation
      field :member_role, ::Types::MemberRoles::MemberRoleType,
        description: 'Updated member role.', null: true
    end
  end
end
