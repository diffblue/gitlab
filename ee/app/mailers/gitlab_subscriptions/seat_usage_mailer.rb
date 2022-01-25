# frozen_string_literal: true

module GitlabSubscriptions
  class SeatUsageMailer < ApplicationMailer
    helper EmailsHelper

    layout 'mailer'

    def exceeded_purchased_seats(user:, subscription_name:, seat_overage:)
      @customer_name = user.name
      @subscription_name = subscription_name
      @seat_overage = seat_overage

      mail(
        to: user.email,
        subject: s_('SubscriptionEmail|Additional charges for your GitLab subscription')
      )
    end
  end
end
