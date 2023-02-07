# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper do
  include Devise::Test::ControllerHelpers
  let(:expected_keys) { UserDetail.registration_objectives.keys - ['joining_team'] }

  describe '#shuffled_registration_objective_options' do
    subject(:shuffled_options) { helper.shuffled_registration_objective_options }

    it 'has values that match all UserDetail registration objective keys' do
      shuffled_option_values = shuffled_options.map { |item| item.last }

      expect(shuffled_option_values).to contain_exactly(*expected_keys)
    end

    it '"other" is always the last option' do
      expect(shuffled_options.last).to eq(['A different reason', 'other'])
    end
  end

  describe '#credit_card_verification_data' do
    before do
      allow(helper).to receive(:current_user).and_return(build(:user))
    end

    it 'returns the expected data' do
      expect(helper.credit_card_verification_data).to eq(
        {
          completed: 'false',
          iframe_url: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_URL,
          allowed_origin: ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
        }
      )
    end
  end

  describe '#arkose_labs_challenge_enabled?' do
    it 'returns true when enabled' do
      allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(true)
      expect(helper.arkose_labs_challenge_enabled?).to eq true
    end

    it 'returns false when not enabled' do
      allow(::Arkose::Settings).to receive(:enabled_for_signup?).and_return(false)
      expect(helper.arkose_labs_challenge_enabled?).to eq false
    end
  end

  describe '#arkose_labs_data' do
    before do
      allow(::Arkose::Settings).to receive(:arkose_public_api_key).and_return('api-key')
      allow(::Arkose::Settings).to receive(:arkose_labs_domain).and_return('domain')
    end

    subject(:data) { helper.arkose_labs_data }

    it { is_expected.to eq({ api_key: 'api-key', domain: 'domain' }) }
  end
end
