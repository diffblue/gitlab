# frozen_string_literal: true

module GroupInviteMembers
  private

  def invite_members(group, invite_source:)
    invite_params = {
      source: group,
      user_id: emails_param[:emails]&.reject(&:blank?)&.join(','),
      access_level: Gitlab::Access::DEVELOPER,
      invite_source: invite_source
    }

    result = Members::CreateService.new(current_user, invite_params).execute

    ::Gitlab::Tracking.event(self.class.name, 'invite_members', label: 'new_group_form', user: current_user) if result[:status] == :success
  end

  def emails_param
    params.require(:group).permit(emails: [])
  end
end
