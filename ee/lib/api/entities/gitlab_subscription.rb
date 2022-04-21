# frozen_string_literal: true

module API
  module Entities
    class GitlabSubscription < Grape::Entity
      expose :plan do
        expose :plan_name, as: :code
        expose :plan_title, as: :name
        expose :trial
        expose :auto_renew
        expose :upgradable?, as: :upgradable
        expose :exclude_guests?, as: :exclude_guests
      end

      expose :usage do
        expose :seats, as: :seats_in_subscription
        expose :seats_in_use
        expose :max_seats_used
        expose :seats_owed
      end

      expose :billing do
        expose :start_date, as: :subscription_start_date
        expose :end_date, as: :subscription_end_date
        expose :trial_ends_on
      end
    end
  end
end
