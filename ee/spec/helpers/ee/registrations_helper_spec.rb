# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper, feature_category: :user_management do
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

  describe '#arkose_labs_data' do
    before do
      allow(::Arkose::Settings).to receive(:arkose_public_api_key).and_return('api-key')
      allow(::Arkose::Settings).to receive(:arkose_labs_domain).and_return('domain')
    end

    subject(:data) { helper.arkose_labs_data }

    it { is_expected.to eq({ api_key: 'api-key', domain: 'domain' }) }
  end

  describe '#register_omniauth_params' do
    let(:result) do
      {
        glm_source: '_glm_source_',
        glm_content: '_glm_content_',
        intent: :register
      }
    end

    before do
      allow(helper)
        .to receive(:glm_tracking_params).and_return({ glm_source: '_glm_source_', glm_content: '_glm_content_' })
    end

    it 'adds intent to register with glm params' do
      expect(helper.register_omniauth_params({})).to eq(result)
    end

    context 'when trial param exists' do
      it 'adds intent to register with glm params and trial' do
        expect(helper.register_omniauth_params({ trial: true })).to eq(result.merge(trial: true))
      end
    end
  end
end
