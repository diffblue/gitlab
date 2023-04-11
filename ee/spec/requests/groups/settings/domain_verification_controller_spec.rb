# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::DomainVerificationController, type: :request,
                                                               feature_category: :system_access do
  shared_examples 'renders 404' do
    it 'renders 404' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /groups/:group_id/-/settings/domain_verification', :saas do
    let_it_be(:user) { create(:user) }

    let(:group) { create(:group) }

    subject(:perform_request) { get group_settings_domain_verification_index_path(group) }

    before do
      stub_licensed_features(domain_verification: licensed_feature_available)
      group.add_member(user, access_level)

      sign_in(user)

      perform_request
    end

    context 'when the feature is available' do
      let(:licensed_feature_available) { true }

      context 'when the user is an owner' do
        let(:access_level) { :owner }

        it 'renders index with 200 status code' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
        end

        context 'when subgroup' do
          let(:group) { create(:group, parent: create(:group)) }

          it_behaves_like 'renders 404'
        end
      end

      context 'when user is not owner' do
        let(:access_level) { :maintainer }

        it_behaves_like 'renders 404'
      end
    end

    context 'when domain verification is unavailable' do
      let(:licensed_feature_available) { false }
      let(:access_level) { :owner }

      it_behaves_like 'renders 404'
    end
  end
end
