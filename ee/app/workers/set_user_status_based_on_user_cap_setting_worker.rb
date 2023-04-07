# frozen_string_literal: true

class SetUserStatusBasedOnUserCapSettingWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ::Gitlab::Utils::StrongMemoize

  feature_category :user_profile

  idempotent!

  def perform(user_id)
    user = User.includes(:identities).find_by_id(user_id) # rubocop: disable CodeReuse/ActiveRecord

    return unless user.activate_based_on_user_cap?

    if User.user_cap_reached?
      send_user_cap_reached_email
      return
    end

    if user.activate
      # Resends confirmation email if the user isn't confirmed yet.
      # Please see Devise's implementation of `resend_confirmation_instructions` for detail.
      user.resend_confirmation_instructions
      user.accept_pending_invitations! if user.active_for_authentication?
      DeviseMailer.user_admin_approval(user).deliver_later

      if user.created_by_id
        reset_token = user.generate_reset_token
        NotificationService.new.new_user(user, reset_token)
      end
    else
      logger.error(message: "Approval of user id=#{user_id} failed")
    end
  end

  private

  def send_user_cap_reached_email
    User.admins.active.each do |user|
      ::Notify.user_cap_reached(user.id).deliver_later
    end
  end
end
