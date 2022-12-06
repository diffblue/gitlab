# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::BillingsController, feature_category: :purchase do
  let_it_be(:user) { create(:user) }

  describe 'GET #index' do
    before do
      sign_in(user)
      stub_application_setting(check_namespace_plan: true)
      allow(Gitlab).to receive(:com?).and_return(true)
      allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
        allow(instance).to receive(:execute).and_return([])
      end
      allow(controller).to receive(:track_experiment_event)
    end

    def get_index
      get :index
    end

    subject { response }

    it 'renders index with 200 status code' do
      get_index

      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to render_template(:index)
    end

    it 'fetch subscription plans data from customers.gitlab.com' do
      data = double
      expect_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
        expect(instance).to receive(:execute).and_return(data)
      end

      get_index

      expect(assigns(:plans_data)).to eq(data)
    end

    context 'when CustomersDot is unavailable' do
      before do
        allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
          allow(instance).to receive(:execute).and_return(nil)
        end
      end

      it 'renders a different partial' do
        get_index

        expect(response).to render_template('shared/billings/customers_dot_unavailable')
      end
    end
  end
end
