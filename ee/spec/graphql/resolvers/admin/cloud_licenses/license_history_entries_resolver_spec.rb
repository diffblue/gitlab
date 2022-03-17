# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Admin::CloudLicenses::LicenseHistoryEntriesResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject(:result) { resolve_license_history_entries }

    let_it_be(:admin) { create(:admin) }

    def create_license(data: {}, license_options: { created_at: Time.current })
      gl_license = create(:gitlab_license, data)
      create(:license, license_options.merge(data: gl_license.export))
    end

    def resolve_license_history_entries(current_user: admin)
      resolve(described_class, ctx: { current_user: current_user })
    end

    context 'when current user is unauthorized' do
      it 'generates an error' do
        unauthorized_user = create(:user)

        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_license_history_entries(current_user: unauthorized_user)
        end
      end
    end

    context 'when no licenses exist' do
      it 'returns an empty array', :enable_admin_mode do
        License.delete_all # delete license created with ee/spec/support/test_license.rb

        expect(result).to eq([])
      end
    end

    it 'returns the license history entries', :enable_admin_mode do
      today = Date.current

      past_license = create_license(
        data: { starts_at: today - 1.month, expires_at: today + 11.months },
        license_options: { created_at: Time.current - 1.month }
      )
      expired_license = create_license(data: { starts_at: today - 1.year, expires_at: today - 1.month })
      another_license = create_license(data: { starts_at: today - 1.month, expires_at: today + 1.year })
      future_license = create_license(
        data: { starts_at: today + 1.month, expires_at: today + 13.months, cloud_licensing_enabled: true }
      )
      current_license = create_license(
        data: { starts_at: today - 15.days, expires_at: today + 11.months, cloud_licensing_enabled: true }
      )

      expect(result).to eq(
        [
          future_license,
          current_license,
          another_license,
          past_license,
          expired_license,
          License.first # created with ee/spec/support/test_license.rb
        ]
      )
    end
  end
end
