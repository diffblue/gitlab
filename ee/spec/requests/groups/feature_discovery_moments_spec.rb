# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'learn about features' do
  describe 'GET /groups/:group_id/-/discover_premium_and_ultimate' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    let(:check_namespace_plan?) { true }
    let(:group_is_eligible_for_trial?) { true }
    let(:user_can_admin_group?) { true }

    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan?)

      unless group_is_eligible_for_trial?
        # We have to stub ::Gitlab.com? in order to use the :gitlab_subscription
        # factory. See: ee/spec/factories/gitlab_subscriptions.rb:5-7
        allow(Gitlab).to receive(:com?).and_return(true)
        create(:gitlab_subscription, :ultimate, namespace: group)
      end

      if user_can_admin_group?
        group.add_owner(user)
      else
        group.add_developer(user)
      end

      login_as(user)

      get group_advanced_features_dashboard_path(group)
    end

    shared_examples 'renders the page' do
      it 'renders the view', :aggregate_failures do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include(s_('InProductMarketing|Discover Premium & Ultimate.').sub('&', '&amp;'))
      end
    end

    shared_examples 'returns 404' do
      it 'returns a 404 status' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    where(
      :check_namespace_plan?,         # plans
      :group_is_eligible_for_trial?,  # trial
      :user_can_admin_group?,         # admin
      :examples_to_run                # behaves like
    ) do
      # plans | trial | admin | behaves like
      true    | true  | true  | 'renders the page'
      false   | true  | true  | 'returns 404'
      true    | false | true  | 'returns 404'
      true    | true  | false | 'returns 404'
    end

    with_them do
      it_behaves_like params[:examples_to_run]
    end
  end
end
