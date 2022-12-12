# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Pipelines::EmailCampaignsController, feature_category: :navigation do
  let_it_be(:user) { create(:user) }

  let(:com) { true }

  subject(:request) do
    get project_pipeline_validate_account_path(project, pipeline)
  end

  before do
    allow(Gitlab).to receive(:com?) { com }
  end

  describe 'GET #validate_account', :snowplow do
    context 'when user has access to the pipeline' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

      before do
        group.add_developer(user)

        sign_in(user)

        request
      end

      it 'emits a snowplow event' do
        expect_snowplow_event(
          category: described_class.name,
          action: 'cta_clicked',
          label: 'account_validation_email',
          project: project,
          user: user,
          namespace: group
        )
      end

      it 'sets session[:start_account_validation] to true' do
        expect(session[:start_account_validation]).to eq(true)
      end

      it 'redirects to the pipeline show page' do
        expect(response).to redirect_to(project_pipeline_path(project, pipeline))
      end

      context 'when not in .com or dev env' do
        let(:com) { false }

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user does not have access to the pipeline' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

      before do
        sign_in(user)

        request
      end

      it 'returns :not_found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not set session[:start_account_validation]' do
        expect(session[:start_account_validation]).to be_nil
      end
    end
  end
end
