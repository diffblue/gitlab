# frozen_string_literal: true

module GitlabSubscriptions
  class PreviewBillableUserChangeService
    attr_reader :current_user, :target_group, :role, :add_group_id, :add_user_emails, :add_user_ids

    def initialize(current_user:, target_group:, role:, **opts)
      @current_user    = current_user
      @target_group    = target_group
      @role            = role
      @add_group_id    = opts[:add_group_id]    || nil
      @add_user_emails = opts[:add_user_emails] || []
      @add_user_ids    = opts[:add_user_ids]    || []
    end

    def execute
      {
        success: true,
        data: {
          has_overage: has_overage?,
          new_billable_user_count: new_billable_user_count,
          seats_in_subscription: seats_in_subscription
        }
      }
    rescue ActiveRecord::RecordNotFound => error
      error_response(error)
    end

    private

    def all_added_user_ids
      ids = Set.new

      ids += add_user_ids
      ids += user_ids_from_added_emails
      ids += user_ids_from_added_group

      ids
    end

    def user_ids_from_added_emails
      @user_ids_from_added_emails ||= begin
        return [] if add_user_emails.blank?

        User.by_any_email(add_user_emails).pluck(:id) # rubocop:disable CodeReuse/ActiveRecord
      end
    end

    def user_ids_from_added_group
      return [] if add_group_id.blank?

      group = GroupFinder.new(current_user).execute(id: add_group_id)

      return [] unless group

      group.billed_user_ids[:user_ids]
    end

    def has_overage?
      new_billable_user_count > seats_in_subscription
    end

    def new_billable_user_count
      @new_billable_user_count ||= begin
        return target_group.billable_members_count if role == :guest && target_group.exclude_guests?

        unmatched_added_emails_count = add_user_emails.count - user_ids_from_added_emails.count

        (target_group.billed_user_ids[:user_ids] + all_added_user_ids).count + unmatched_added_emails_count
      end
    end

    def seats_in_subscription
      @seats_in_subscription ||= target_group.gitlab_subscription&.seats || 0
    end

    def error_response(error)
      {
        success: false,
        error: error.message
      }
    end
  end
end
