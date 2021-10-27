# frozen_string_literal: true

class AdminEmailsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :team_planning

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(recipient_id, subject, body)
    recipient_list(recipient_id).pluck(:id).uniq.each do |user_id|
      Notify.send_admin_notification(user_id, subject, body).deliver_later
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def recipient_list(recipient_id)
    case recipient_id
    when 'all'
      User.active.subscribed_for_admin_email
    when /group-(\d+)\z/
      Group.find(Regexp.last_match(1)).users_with_descendants.subscribed_for_admin_email
    when /project-(\d+)\z/
      Project.find(Regexp.last_match(1)).authorized_users.active.subscribed_for_admin_email
    end
  end
end
