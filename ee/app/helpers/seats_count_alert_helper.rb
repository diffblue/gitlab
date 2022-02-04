# frozen_string_literal: true

module SeatsCountAlertHelper
  def display_seats_count_alert!
    @display_seats_count_alert = true
  end

  def learn_more_link
    link_to _('Learn more.'), help_page_path('subscriptions/quarterly_reconciliation'), target: '_blank', rel: 'noopener noreferrer'
  end

  def group_name
    root_namespace&.name
  end

  def remaining_seats_count
    return unless total_seats_count && seats_in_use

    total_seats_count - seats_in_use
  end

  def seats_usage_link
    return unless root_namespace

    link_to _('View seat usage'), current_usage_quotas_path, class: 'btn gl-alert-action btn-info btn-md gl-button'
  end

  def show_seats_count_alert?
    return false unless ::Gitlab.dev_env_or_com? && group_with_owner? && current_subscription
    return false if user_dismissed_alert?

    !!@display_seats_count_alert
  end

  def total_seats_count
    current_subscription&.seats
  end

  private

  def user_dismissed_alert?
    current_user.dismissed_callout_for_group?(
      feature_name: Users::GroupCalloutsHelper::APPROACHING_SEAT_COUNT_THRESHOLD,
      group: root_namespace,
      ignore_dismissal_earlier_than: last_member_added_at
    )
  end

  def last_member_added_at
    root_namespace&.last_billed_user_created_at
  end

  def group_with_owner?
    root_namespace&.group_namespace? && root_namespace&.has_owner?(current_user)
  end

  def root_namespace
    @project&.root_ancestor || @group&.root_ancestor
  end

  def current_subscription
    root_namespace&.gitlab_subscription
  end

  def seats_in_use
    current_subscription&.seats_in_use
  end

  def current_usage_quotas_path
    usage_quotas_path(root_namespace, anchor: 'seats-quota-tab')
  end
end
