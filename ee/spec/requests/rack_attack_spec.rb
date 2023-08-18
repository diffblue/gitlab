# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rack Attack EE throttles', feature_category: :system_access do
  include RackAttackSpecHelpers

  let(:project) { create(:project) }

  include_context 'rack attack cache store'

  shared_examples_for 'incident management rate limiting' do
    let(:settings) { Gitlab::CurrentSettings.current_application_settings }

    let(:token) { double(plaintext_token: '123456') }
    let(:period) { period_in_seconds.seconds }

    let(:settings_to_set) do
      {
        throttle_incident_management_notification_enabled: throttle_enabled,
        throttle_incident_management_notification_per_period: requests_per_period,
        throttle_incident_management_notification_period_in_seconds: period_in_seconds
      }
    end

    let(:post_args) { { headers: oauth_token_headers(token) } }

    before do
      allow_next_instance_of(Projects::Alerting::NotifyService) do |instance|
        allow(instance).to receive(:execute).and_return(ServiceResponse.success)
      end

      stub_application_setting(settings_to_set)
    end

    context 'limits set' do
      let(:requests_per_period) { 1 }
      let(:period_in_seconds) { 10000 }

      context 'when the throttle is enabled' do
        let(:throttle_enabled) { true }

        it 'rejects requests over the rate limit' do
          # At first, allow requests under the rate limit.
          requests_per_period.times do
            post(path, **post_args)
            expect(response).to have_gitlab_http_status(:ok)
          end

          # the last straw
          expect_rejection { post(path, **post_args) }
        end

        it 'allows requests after throttling and then waiting for the next period' do
          requests_per_period.times do
            post(path, **post_args)
            expect(response).to have_gitlab_http_status(:ok)
          end

          expect_rejection { post(path, **post_args) }

          travel_back
          travel_to(period.from_now) do
            requests_per_period.times do
              post(path, **post_args)
              expect(response).to have_gitlab_http_status(:ok)
            end

            expect_rejection { post(path, **post_args) }
          end
        end
      end

      context 'when the throttle is disabled' do
        let(:throttle_enabled) { false }

        it 'allows requests over the rate limit' do
          # At first, allow requests under the rate limit.
          requests_per_period.times do
            post(path, **post_args)
            expect(response).to have_gitlab_http_status(:ok)
          end

          # requests still allowed
          post(path, **post_args)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'requests to prometheus alert notify endpoint with oauth token' do
    it_behaves_like 'incident management rate limiting' do
      let(:path) { "/#{project.full_path}/prometheus/alerts/notify" }
    end
  end

  describe 'requests to generic alert notify endpoint with oauth token' do
    it_behaves_like 'incident management rate limiting' do
      let(:path) { "/#{project.full_path}/alerts/notify" }
    end
  end

  describe 'requests to AlertManagement::HttpIntegration notify endpoint with oauth token' do
    it_behaves_like 'incident management rate limiting' do
      let(:path) { "/#{project.full_path}/alerts/notify/http-integration-name/eddd36969b2d3d6a" }
    end
  end
end
