# frozen_string_literal: true

class GroupHookPolicy < ::BasePolicy
  delegate { @subject.group }

  rule { can?(:admin_group) }.policy do
    enable :destroy_web_hook
  end
end
