# frozen_string_literal: true

RSpec.shared_examples 'pushes wip limits to frontend' do
  context 'self-hosted with correct license' do
    before do
      stub_licensed_features(wip_limits: true)
    end

    it 'is enabled for all groups if the license is correct' do
      expect(subject).to receive(:push_frontend_feature_flag).at_least(:once)

      get :index, params: params
    end
  end

  context 'on .com', :saas do
    before do
      enable_namespace_license_check!
    end

    context 'for group with correct plan' do
      before do
        namespace = parent.is_a?(Group) ? parent : parent.namespace
        create(:gitlab_subscription, namespace: namespace, hosted_plan: create(:bronze_plan))
      end

      it 'is enabled' do
        expect(subject).to receive(:push_frontend_feature_flag).at_least(:once)

        get :index, params: params
      end
    end

    context 'for group with incorrect or no plan' do
      it 'is not enabled' do
        expect(subject).not_to receive(:push_frontend_feature_flag).with(:wip_limits, anything)

        get :index, params: params
      end
    end
  end
end
