# frozen_string_literal: true

module UsageQuotasHelpers
  def buy_minutes_subscriptions_link(group)
    buy_minutes_subscriptions_path(selected_group: group.id)
  end
end

UsageQuotasHelpers.prepend_mod
