# frozen_string_literal: true

module EE
  module ProjectMemberPresenter
    def group_sso?
      false
    end

    def group_managed_account?
      false
    end

    def can_ban?
      false
    end

    def can_unban?
      false
    end

    private

    def override_member_permission
      :override_project_member
    end
  end
end
