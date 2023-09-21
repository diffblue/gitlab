# frozen_string_literal: true

module MemberRoles
  class UpdateService < BaseService
    def execute(member_role)
      return authorized_error unless allowed?

      update_member_role(member_role)
    end

    private

    def update_member_role(member_role)
      member_role.assign_attributes(params.slice(:name, :description))

      if member_role.save
        ::ServiceResponse.success(payload: { member_role: member_role })
      else
        ::ServiceResponse.error(message: member_role.errors.full_messages, payload: { member_role: member_role.reset })
      end
    end
  end
end
