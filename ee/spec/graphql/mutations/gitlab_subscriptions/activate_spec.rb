# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::GitlabSubscriptions::Activate do
  include AdminModeHelper

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  let_it_be(:user) { create(:admin) }
  let_it_be(:created_license) { License.last }

  let(:activation_code) { 'activation_code' }
  let(:future_subscriptions) { [] }
  let(:result) { { success: true, license: created_license, future_subscriptions: future_subscriptions } }

  describe '#resolve' do
    before do
      enable_admin_mode!(user)

      allow_next_instance_of(::GitlabSubscriptions::ActivateService) do |service|
        expect(service).to receive(:execute).with(activation_code).and_return(result)
      end
    end

    context 'when successful' do
      it 'returns no errors, a license and no future subscriptions' do
        result = mutation.resolve(activation_code: activation_code)

        expect(result).to eq({ errors: [], license: created_license, future_subscriptions: future_subscriptions })
      end

      context 'when there are future subscriptions' do
        let(:future_subscriptions) do
          future_date = 4.days.from_now.to_date

          [
            {
              cloud_license_enabled: true,
              offline_cloud_license_enabled: false,
              plan: 'ultimate',
              name: 'User Example',
              company: 'Example Inc',
              email: 'user@example.com',
              starts_at: future_date.to_s,
              expires_at: (future_date + 1.year).to_s,
              users_in_license_count: 10
            }
          ]
        end

        it 'returns the no errors, a license and the future subscriptions' do
          result = mutation.resolve(activation_code: activation_code)

          expect(result).to eq({ errors: [], license: created_license, future_subscriptions: future_subscriptions })
        end
      end
    end

    context 'when failure' do
      let(:result) { { success: false, errors: ['foo'] } }

      it 'returns errors' do
        result = mutation.resolve(activation_code: activation_code)

        expect(result).to eq({ errors: ['foo'], license: nil, future_subscriptions: [] })
      end
    end

    context 'when non-admin' do
      let_it_be(:user) { create(:user) }

      it 'raises errors' do
        expect do
          mutation.resolve(activation_code: activation_code)
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
