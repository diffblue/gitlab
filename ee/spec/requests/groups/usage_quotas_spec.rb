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
        allow_next_instance_of(Namespaces::CheckStorageSizeService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.success(
              payload: {
                alert_level: :info,
                usage_message: usage_message,
                explanation_message: "Explanation",
                root_namespace: group
              }
            )
          )
        end
      end

      it 'does not display storage alert' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to include(usage_message)
      end
    end

    context 'free_user_cap feature flag' do
      subject(:body) { response.body }

      before do
        stub_feature_flags(free_user_cap: free_user_cap_enabled)
        send_request
      end

      context 'when disabled' do
        let(:free_user_cap_enabled) { false }

        it { is_expected.to have_pushed_frontend_feature_flags(freeUserCap: false)}
      end

      context 'when enabled' do
        let(:free_user_cap_enabled) { true }

        it { is_expected.to have_pushed_frontend_feature_flags(freeUserCap: true)}
      end
    end

    context 'preview_free_user_cap feature flag' do
      subject(:body) { response.body }

      before do
        stub_feature_flags(preview_free_user_cap: preview_free_user_cap_enabled)
        send_request
      end

      context 'when disabled' do
        let(:preview_free_user_cap_enabled) { false }

        it { is_expected.to have_pushed_frontend_feature_flags(previewFreeUserCap: false)}
      end

      context 'when enabled' do
        let(:preview_free_user_cap_enabled) { true }

        it { is_expected.to have_pushed_frontend_feature_flags(previewFreeUserCap: true)}
      end
    end

    context 'container_registry_namespace_statistics feature flag' do
      subject { response.body }

      before do
        stub_feature_flags(container_registry_namespace_statistics: container_registry_namespace_statistics_enabled)
        send_request
      end

      context 'when disabled' do
        let(:container_registry_namespace_statistics_enabled) { false }

        it { is_expected.to have_pushed_frontend_feature_flags(containerRegistryNamespaceStatistics: false)}
      end

      context 'when enabled' do
        let(:container_registry_namespace_statistics_enabled) { true }

        it { is_expected.to have_pushed_frontend_feature_flags(containerRegistryNamespaceStatistics: true)}
      end
    end

    def send_request
      get group_usage_quotas_path(group)
    end
  end
end
