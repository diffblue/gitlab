# frozen_string_literal: true

module RemoteDevelopment
  # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-25400
  class WorkspacePolicy < BasePolicy
    delegate { subject.project }

    condition(:workspace_owner) { user.id == workspace&.user_id }

    rule { workspace_owner & can?(:developer_access) }.enable :update_workspace

    rule { workspace_owner }.enable :read_workspace

    def workspace
      subject
    end
  end
end
