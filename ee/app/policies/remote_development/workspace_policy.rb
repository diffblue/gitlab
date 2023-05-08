# frozen_string_literal: true

module RemoteDevelopment
  class WorkspacePolicy < BasePolicy
    delegate { subject.project }

    condition(:workspace_owner) { user.id == workspace&.user_id }

    # noinspection RubyResolve
    rule { workspace_owner & can?(:developer_access) }.enable :update_workspace

    # noinspection RubyResolve
    rule { workspace_owner }.enable :read_workspace

    def workspace
      subject
    end
  end
end
