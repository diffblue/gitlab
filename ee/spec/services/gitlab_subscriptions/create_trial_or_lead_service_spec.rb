# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CreateTrialOrLeadService do
  let(:user) { build(:user) }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    where(:trial, :service) do
      'true'  | :generate_trial
      'false' | :generate_hand_raise_lead
    end

    with_them do
      it 'successfully creates a trial or lead' do
        allow(Gitlab::SubscriptionPortal::Client).to receive(service).and_return({ success: true })

        result = described_class.new(**{ user: user, params: { trial: trial } }).execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be true
      end

      it 'error while creating trial or lead' do
        allow(Gitlab::SubscriptionPortal::Client).to receive(service).and_return({ success: false })

        result = described_class.new(**{ user: user, params: { trial: trial } }).execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be false
      end
    end
  end
end
