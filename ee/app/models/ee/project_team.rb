# frozen_string_literal: true

module EE
  module ProjectTeam
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :add_members
    def add_members(
      users,
      access_level,
      current_user: nil,
      expires_at: nil,
      tasks_to_be_done: [],
      tasks_project_id: nil
    )
      return false if group_member_lock

      super
    end

    override :add_member
    def add_member(user, access_level, current_user: nil, expires_at: nil)
      if group_member_lock && !user.project_bot?
        return false
      end

      super
    end

    private

    def group_member_lock
      group && group.membership_lock
    end
  end
end
