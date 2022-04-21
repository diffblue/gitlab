# frozen_string_literal: true

RSpec.shared_examples_for 'license type fields' do
  include GraphqlHelpers

  context 'with license type fields' do
    let(:license_fields) do
      %w[id type plan name email company starts_at expires_at block_changes_at activated_at users_in_license_count]
    end

    it { expect(described_class).to include_graphql_fields(*license_fields) }

    describe 'field values' do
      let_it_be(:starts_at) { Date.current - 3.months }
      let_it_be(:expires_at) { Date.current + 9.months }
      let_it_be(:block_changes_at) { Date.current + 10.months }
      let_it_be(:activated_at) { DateTime.current - 2.months }
      let_it_be(:licensee) do
        {
          'Name' => 'User Example',
          'Email' => 'user@example.com',
          'Company' => 'Example Inc.'
        }
      end

      let_it_be(:restrictions) do
        {
          id: 5,
          plan: 'ultimate',
          active_user_count: 25
        }
      end

      let_it_be(:license) do
        create_current_license(
          licensee: licensee,
          restrictions: restrictions,
          starts_at: starts_at,
          expires_at: expires_at,
          block_changes_at: block_changes_at,
          activated_at: activated_at,
          cloud_licensing_enabled: true
        )
      end

      subject { resolve_field(field_name, license) }

      describe 'id' do
        let(:field_name) { :id }

        it { is_expected.to include(license.license_id.to_s) }
      end

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

      describe 'block_changes_at' do
        let(:field_name) { :block_changes_at }

        it { is_expected.to eq(block_changes_at) }
      end

      describe 'activated_at' do
        let(:field_name) { :activated_at }

        it { is_expected.to eq(activated_at.change(usec: 0)) }
      end

      describe 'users_in_license_count' do
        let(:field_name) { :users_in_license_count }

        it { is_expected.to eq(25) }
      end

      describe 'created_at' do
        let(:field_name) { :created_at }

        it { is_expected.to eq(license.created_at) }
      end
    end
  end
end
