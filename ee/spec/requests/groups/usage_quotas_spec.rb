# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view usage quotas' do
  describe 'GET /groups/:group/-/usage_quotas' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    before_all do
      stub_feature_flags(usage_quotas_pipelines_vue: false)
      group.add_owner(user)
    end

    before do
      login_as(user)
    end

    context 'when storage size is over limit' do
      let(:usage_message) { FFaker::Lorem.sentence }

      before do
        allow_next_instance_of(EE::Namespace::Storage::Notification, group, user) do |notification|
          allow(notification).to receive(:payload).and_return({
            alert_level: :info,
            usage_message: usage_message,
            explanation_message: "Explanation",
            root_namespace: group.root_ancestor
          })
        end
      end

      it 'does not display storage alert' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to include(usage_message)
      end
    end

    def send_request
      get group_usage_quotas_path(group)
    end
  end
end
