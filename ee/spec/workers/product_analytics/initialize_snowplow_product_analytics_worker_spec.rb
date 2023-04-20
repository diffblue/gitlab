# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::InitializeSnowplowProductAnalyticsWorker, feature_category: :product_analytics do
  let_it_be(:project) { create(:project) }

  let(:app_id) { SecureRandom.hex(16) }

  subject(:worker) { described_class.new.perform(project.id) }

  before do
    stub_licensed_features(product_analytics: true)
    stub_application_setting(product_analytics_configurator_connection_string: 'https://gl-product-analytics-configurator.gl.com:4567')
    stub_feature_flags(product_analytics_dashboards: true)
    stub_feature_flags(product_analytics_snowplow_support: true)
  end

  shared_examples 'a worker that did not make any HTTP calls' do
    it 'makes no HTTP calls to the configurator API' do
      subject

      expect(Gitlab::HTTP).not_to receive(:post)
    end
  end

  context 'when response is successful' do
    before do
      stub_request(:post, "https://gl-product-analytics-configurator.gl.com:4567/setup-project/gitlab_project_#{project.id}")
        .to_return(status: 200, body: { app_id: app_id, db_name: "gitlab_project_#{project.id}" }.to_json, headers: {})
    end

    it 'persists the instrumentation key' do
      expect { subject }
        .to change { project.reload.project_setting.product_analytics_instrumentation_key }.from(nil).to(app_id)
    end
  end

  context 'when response is unsuccessful' do
    before do
      stub_request(:post, "https://gl-product-analytics-configurator.gl.com:4567/setup-project/gitlab_project_#{project.id}")
        .to_return(status: 401, body: {}.to_json, headers: {})
    end

    it 'raises a RuntimeError' do
      expect { subject }.to raise_error(RuntimeError)
    end
  end

  context 'when product_analytics_dashboards feature flag is disabled' do
    before do
      stub_feature_flags(product_analytics_dashboards: false)
    end

    it_behaves_like 'a worker that did not make any HTTP calls'
  end

  context 'when snowplow support is not enabled' do
    before do
      stub_feature_flags(product_analytics_snowplow_support: false)
    end

    it_behaves_like 'a worker that did not make any HTTP calls'
  end

  context 'when feature is not licensed' do
    before do
      stub_licensed_features(product_analytics: false)
    end

    it_behaves_like 'a worker that did not make any HTTP calls'
  end
end
