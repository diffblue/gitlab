# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Admin::CloudLicenses::CurrentLicenseResolver do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Admin::CloudLicenses::CurrentLicenseType)
  end

  describe '#resolve' do
    subject(:result) { resolve_current_license }

    let_it_be(:admin) { create(:admin) }
    let_it_be(:license) { create_current_license }

    def resolve_current_license(current_user: admin)
      resolve(described_class, ctx: { current_user: current_user })
    end

    context 'when current user is unauthorized' do
      it 'generates an error' do
        unauthorized_user = create(:user)

        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_current_license(current_user: unauthorized_user)
        end
      end
    end

    context 'when there is no current license', :enable_admin_mode do
      it 'returns nil' do
        License.delete_all # delete existing license

        expect(result).to be_nil
      end
    end

    it 'returns the current license', :enable_admin_mode do
      expect(result).to eq(license)
    end
  end
end
