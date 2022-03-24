# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SubscriptionFutureEntry'], :enable_admin_mode do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }

  def query(field_name)
    %(
      {
        subscriptionFutureEntries {
          nodes {
            #{field_name}
          }
        }
      }
    )
  end

  def query_field(field_name)
    GitlabSchema.execute(query(field_name), context: { current_user: admin }).as_json
  end

  it { expect(described_class.graphql_name).to eq('SubscriptionFutureEntry') }

  context 'with fields' do
    let(:fields) do
      %w[plan name email company starts_at expires_at users_in_license_count]
    end

    it { expect(described_class).to include_graphql_fields(*fields) }

    describe 'field values' do
      let_it_be(:starts_at) { Date.current - 3.months }
      let_it_be(:expires_at) { Date.current + 9.months }

      let_it_be(:subscription) do
        {
          'type' => License::ONLINE_CLOUD_TYPE,
          'plan' => 'ultimate',
          'name' => 'User Example',
          'email' => 'user@example.com',
          'company' => 'Example Inc.',
          'starts_at' => starts_at,
          'expires_at' => expires_at,
          'users_in_license_count' => 25
        }
      end

      subject { resolve_field(field_name, subscription) }

      describe 'type' do
        let(:field_name) { :type }

        it { is_expected.to eq(License::ONLINE_CLOUD_TYPE) }
      end

      describe 'plan' do
        let(:field_name) { :plan }

        it { is_expected.to eq('ultimate') }
      end

      describe 'name' do
        let(:field_name) { :name }

        it { is_expected.to eq('User Example') }
      end

      describe 'email' do
        let(:field_name) { :email }

        it { is_expected.to eq('user@example.com') }
      end

      describe 'company' do
        let(:field_name) { :company }

        it { is_expected.to eq('Example Inc.') }
      end

      describe 'starts_at' do
        let(:field_name) { :starts_at }

        it { is_expected.to eq(starts_at) }
      end

      describe 'expires_at' do
        let(:field_name) { :expires_at }

        it { is_expected.to eq(expires_at) }
      end

      describe 'users_in_license_count' do
        let(:field_name) { :users_in_license_count }

        it { is_expected.to eq(25) }
      end
    end
  end
end
