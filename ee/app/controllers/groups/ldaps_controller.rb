# frozen_string_literal: true

class Groups::LdapsController < Groups::ApplicationController
  before_action :group
  before_action :authorize_admin_group!
  before_action :check_enabled_extras!

  feature_category :system_access

  def sync
    # A group can transition to pending if it is in the ready or failed
    # state. If it is in the started or pending state, then that means
    # it is already running. If the group doesn't validate, then it's
    # likely the group will never transition out of its current state,
    # so we should tell the group owner.
    if @group.pending_ldap_sync
      LdapGroupSyncWorker.perform_async(@group.id) # rubocop:disable CodeReuse/Worker
      message = 'The group sync has been scheduled'
    elsif @group.valid?
      message = 'The group sync is already scheduled'
    else
      message = "This group is in an invalid state: #{@group.errors.full_messages.join(', ')}"
      return redirect_to group_group_members_path(@group), alert: message
    end

    redirect_to group_group_members_path(@group), notice: message
  end

  private

  def check_enabled_extras!
    render_404 unless Gitlab::Auth::Ldap::Config.group_sync_enabled?
  end
end
