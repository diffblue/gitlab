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

        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_entries(current_user: unauthorized_user)
        end
      end
    end

    context 'when no subscriptions exist', :enable_admin_mode do
      it 'returns an empty array' do
        allow(::Gitlab::CurrentSettings).to receive(:future_subscriptions).and_return([])

        expect(result).to eq([])
      end
    end

    context 'when future subscriptions exist', :enable_admin_mode do
      let(:cloud_license_enabled) { true }
      let(:offline_cloud_licensing) { false }
      let(:subscription) do
        {
          'cloud_license_enabled' => cloud_license_enabled,
          'offline_cloud_licensing' => offline_cloud_licensing,
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

      it 'returns the subscription future entries' do
        expect(result).to match(
          [
            hash_including(
              'type' => License::ONLINE_CLOUD_TYPE,
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

        it 'returns type as legacy_license' do
          expect(result.first).to include('type' => License::LEGACY_LICENSE_TYPE)
        end
      end

      context 'cloud_license_enabled is true and offline_cloud_licensing is true' do
        let(:offline_cloud_licensing) { true }

        it 'returns type as offline_cloud' do
          expect(result.first).to include('type' => License::OFFLINE_CLOUD_TYPE)
        end
      end
    end
  end
end
