# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::SeatUsageMailer do
  include EmailSpec::Matchers

  describe '#exceeded_purchased_seats' do
    context 'when supplied valid args' do
      let_it_be(:user) { create(:user, name: 'John Doe') }

      subject do
        described_class.exceeded_purchased_seats(user: user, subscription_name: 'A-123456', seat_overage: 5)
      end

      it { is_expected.to have_subject 'Additional charges for your GitLab subscription' }
      it { is_expected.to have_body_text "Dear John Doe," }
      it { is_expected.to have_body_text "your GitLab subscription <strong>A-123456</strong> by <strong>5</strong>" }
    end
  end
end
