# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::PersonalAccessTokens::RevokeService, feature_category: :system_access do
  describe '#execute' do
    subject { service.execute }

    let(:service) { PersonalAccessTokens::RevokeService.new(current_user, token: token, group: group) }

    shared_examples_for 'a successfully revoked token' do
      it { expect(subject.success?).to be true }
      it { expect(service.token.revoked?).to be true }
    end

    shared_examples_for 'an unsuccessfully revoked token' do
      it { expect(subject.success?).to be false }
      it { expect(service.token.revoked?).to be false }
    end

    context 'managed group' do
      let_it_be(:group) { create(:group_with_managed_accounts) }
      let_it_be(:managed_user) { create(:user, :group_managed, managing_group: group) }
      let_it_be(:group_owner) { create(:user) }
      let_it_be(:group_developer) { create(:user, :group_managed, managing_group: group) }

      before_all do
        group.add_owner(group_owner)
        group.add_developer(group_developer)
      end

      context 'when current user is a managed group owner' do
        let_it_be(:current_user) { group_owner }
        let_it_be(:token) { create(:personal_access_token, user: managed_user) }

        it_behaves_like 'a successfully revoked token'

        context 'and an empty token is given' do
          let_it_be(:token) { nil }

          it { expect(subject.success?).to be false }
        end
      end

      context 'when current user is a group owner of a different managed group' do
        let_it_be(:group) { create(:group_with_managed_accounts) }
        let_it_be(:group_owner2) { create(:user) }
        let_it_be(:current_user) { group_owner2 }
        let_it_be(:token) { create(:personal_access_token, user: managed_user) }

        before_all do
          group.add_owner(group_owner2)
        end

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'when current user is not a managed group owner' do
        let_it_be(:current_user) { group_developer }
        let_it_be(:token) { create(:personal_access_token, user: managed_user) }

        it_behaves_like 'an unsuccessfully revoked token'
      end

      context 'when current user is not a managed user' do
        let_it_be(:current_user) { group_owner }
        let_it_be(:token) { create(:personal_access_token, user: create(:user)) }

        it_behaves_like 'an unsuccessfully revoked token'
      end
    end
  end
end
