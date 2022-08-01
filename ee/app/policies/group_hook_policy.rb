# frozen_string_literal: true

class GroupHookPolicy < ::BasePolicy
  delegate(:group)

  rule { can?(:admin_group) }.policy do
    enable :read_web_hook
    enable :destroy_web_hook
  end
end
