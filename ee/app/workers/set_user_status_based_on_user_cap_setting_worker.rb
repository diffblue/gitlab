# frozen_string_literal: true

class SetUserStatusBasedOnUserCapSettingWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ::Gitlab::Utils::StrongMemoize

  feature_category :users
  tags :exclude_from_kubernetes

  idempotent!

  def perform(user_id)
    user = User.includes(:identities).find_by_id(user_id) # rubocop: disable CodeReuse/ActiveRecord

    return if blocked_auto_created_omniauth_user?(user)
    return unless user.blocked_pending_approval?
    return if user_cap_max.nil?

    if user_cap_reached?
      send_user_cap_reached_email
      return
    end

    if user.activate
      # Resends confirmation email if the user isn't confirmed yet.
      # Please see Devise's implementation of `resend_confirmation_instructions` for detail.
      user.resend_confirmation_instructions
      user.accept_pending_invitations! if user.active_for_authentication?
      DeviseMailer.user_admin_approval(user).deliver_later
    else
      logger.error(message: "Approval of user id=#{user_id} failed")
    end
  end

  private

  def user_cap_max
    strong_memoize(:user_cap_max) do
      ::Gitlab::CurrentSettings.new_user_signups_cap
    end
  end

  def current_billable_users_count
    User.billable.count
  end

  def user_cap_reached?
    current_billable_users_count >= user_cap_max
  end

  def send_user_cap_reached_email
    User.admins.active.each do |user|
      ::Notify.user_cap_reached(user.id).deliver_later
    end
  end

  def blocked_auto_created_omniauth_user?(user)
    ::Gitlab.config.omniauth.block_auto_created_users && user.identities.any?
  end
end
