# frozen_string_literal: true

module Members
  class MemberRolePolicy < BasePolicy
    delegate { @subject.namespace }

    condition(:custom_roles_allowed) do
      @subject.namespace&.custom_roles_enabled?
    end

    rule { ~custom_roles_allowed }.policy do
      prevent_all
    end
  end
end
