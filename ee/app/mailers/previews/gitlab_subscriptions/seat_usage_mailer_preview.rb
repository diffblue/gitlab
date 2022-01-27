# frozen_string_literal: true

module GitlabSubscriptions
  class SeatUsageMailerPreview < ActionMailer::Preview
    def exceeded_purchased_seats
      ::GitlabSubscriptions::SeatUsageMailer.exceeded_purchased_seats(
        user: User.first,
        subscription_name: 'A-123456',
        seat_overage: 5
      )
    end
  end
end
