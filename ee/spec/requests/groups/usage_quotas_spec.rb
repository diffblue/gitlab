# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view usage quotas', feature_category: :subscription_cost_management do
  describe 'GET /groups/:group/-/usage_quotas' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    before_all do
      group.add_owner(user)
    end

    before do
      login_as(user)
    end

    context 'when storage size is over limit' do
      let(:payload) do
        {
          alert_level: :info,
          usage_message: FFaker::Lorem.sentence,
          explanation_message: "Explanation",
          root_namespace: group.root_ancestor
        }
      end

      before do
        allow_next_instance_of(EE::Namespace::Storage::Notification, group, user) do |notification|
          allow(notification).to receive(:payload).and_return(payload)
        end
      end

      it 'does not display storage alert' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to include(payload[:usage_message])
      end
    end

    def send_request
      get group_usage_quotas_path(group)
    end
  end
end
