# frozen_string_literal: true

class PathLockPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  delegate { @subject.project }

  condition(:is_author) { @user && @subject.user == @user }
  condition(:is_project_member) { @user && @subject.project && @subject.project.team.member?(user) }

  rule { is_author & is_project_member }.enable :admin_path_locks
end
