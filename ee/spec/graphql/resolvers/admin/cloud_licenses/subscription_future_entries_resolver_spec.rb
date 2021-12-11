# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Admin::CloudLicenses::SubscriptionFutureEntriesResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject(:result) { resolve_entries }

    let_it_be(:admin) { create(:admin) }

    def resolve_entries(current_user: admin)
      resolve(described_class, ctx: { current_user: current_user })
    end

    context 'when current user is unauthorized' do
      it 'raises error' do
        unauthorized_user = create(:user)

        expect do
          resolve_entries(current_user: unauthorized_user)
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when no subscriptions exist' do
      it 'returns an empty array', :enable_admin_mode do
        allow(::Gitlab::CurrentSettings).to receive(:future_subscriptions).and_return([])

        expect(result).to eq([])
      end
    end

    context 'when future subscriptions exist' do
      let(:cloud_license_enabled) { true }
      let(:subscription) do
        {
          'cloud_license_enabled' => cloud_license_enabled,
          'plan' => 'ultimate',
          'name' => 'User Example',
          'email' => 'user@example.com',
          'company' => 'Example Inc.',
          'starts_at' => '2021-12-08',
          'expires_at' => '2022-12-08',
          'users_in_license_count' => 25
        }
      end

      before do
        allow(::Gitlab::CurrentSettings).to receive(:future_subscriptions).and_return([subscription])
      end

      it 'returns the subscription future entries', :enable_admin_mode do
        expect(result).to match(
          [
            hash_including(
              'type' => 'cloud',
              'plan' => 'ultimate',
              'name' => 'User Example',
              'email' => 'user@example.com',
              'company' => 'Example Inc.',
              'starts_at' => '2021-12-08',
              'expires_at' => '2022-12-08',
              'users_in_license_count' => 25
            )
          ]
        )
      end

      context 'cloud_license_enabled is false' do
        let(:cloud_license_enabled) { false }

        it 'returns type as license_file', :enable_admin_mode do
          expect(result.first).to include('type' => 'license_file')
        end
      end
    end
  end
end
