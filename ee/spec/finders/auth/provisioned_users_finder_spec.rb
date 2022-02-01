# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::ProvisionedUsersFinder do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:regular_user) { create(:user) }
    let_it_be(:saml_provider) { create(:saml_provider, group: group) }
    let_it_be(:scim_identity) { create(:scim_identity, group: group) }
    let_it_be(:developer) { create(:user).tap { |u| group.add_developer(u) } }
    let_it_be(:maintainer) { create(:user).tap { |u| group.add_maintainer(u) } }

    let_it_be(:provisioned_user) { create(:user, provisioned_by_group_id: group.id, created_at: 2.years.ago) }
    let_it_be(:blocked_provisioned_user) { create(:user, :blocked, provisioned_by_group_id: group.id) }
    let_it_be(:non_provisioned_user) { create(:user) { |u| group.add_maintainer(u) } }
    let_it_be(:user) { create(:user) { |u| group.add_maintainer(u) } }

    let(:params) { {} }

    include_context 'UsersFinder#execute filter by project context'

    subject(:finder) { described_class.new(user, params).execute }

    describe '#base_scope' do
      context 'when provisioning_group_id param is not passed' do
        let(:params) { { provisioning_group_id: nil } }

        it 'raises provisioning group error' do
          expect { finder }.to raise_error RuntimeError, 'Provisioning group is required for ProvisionedUsersFinder'
        end
      end

      context 'when provisioning_group_id param is passed' do
        let(:params) { { provisioning_group_id: group.id } }

        it 'returns provisioned_user' do
          users = finder
          expect(users).to eq([blocked_provisioned_user, provisioned_user])
        end
      end
    end

    describe '#by_search' do
      let(:params) { { provisioning_group_id: group.id, search: provisioned_user.email } }

      it 'filters by search' do
        users = finder

        expect(users).to eq([provisioned_user])
      end
    end
  end
end
