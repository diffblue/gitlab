# frozen_string_literal: true

module EE
  module MemberPresenter
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Utils::DelegatorOverride

    def can_update?
      super || can_override?
    end

    override :can_override?
    def can_override?
      can?(current_user, override_member_permission, member)
    end

    delegator_override :human_access
    def human_access
      return format(s_("MemberRole|%{role} - custom"), role: super) if member_role

      super
    end

    private

    def override_member_permission
      raise NotImplementedError
    end
  end
end
