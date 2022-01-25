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
    return false unless root_namespace&.group_namespace?
    return false unless root_namespace&.has_owner?(current_user)
    return false unless current_subscription

    !!@display_seats_count_alert
  end

  def total_seats_count
    current_subscription&.seats
  end

  private

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
