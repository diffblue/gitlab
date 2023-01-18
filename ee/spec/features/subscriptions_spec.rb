# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscriptions Content Security Policy', feature_category: :purchase do
  include ContentSecurityPolicyHelpers

  subject { response_headers['Content-Security-Policy'] }

  let_it_be(:default_csp_values) { "'self' https://some-cdn.test" }
  let_it_be(:onetrust_url) { 'https://*.onetrust.com' }
  let_it_be(:cookielaw_url) { 'https://cdn.cookielaw.org' }
  let_it_be(:google_tag_manager_url) { '*.googletagmanager.com' }
  let_it_be(:google_analytics_url) { '*.google-analytics.com' }
  let_it_be(:google_analytics_google_url) { '*.analytics.google.com' }

  before do
    stub_request(:get, /.*gitlab_plans.*/).to_return(status: 200, body: "{}")

    setup_csp_for_controller(SubscriptionsController, csp, times: 3)

    sign_in(create(:user))

    visit new_subscriptions_path
  end

  context 'when there is no global CSP config' do
    let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

    it { is_expected.to be_blank }
  end

  context 'when a global CSP config exists', :do_not_stub_snowplow_by_default do
    let(:csp) do
      ActionDispatch::ContentSecurityPolicy.new do |p|
        p.script_src(*default_csp_values.split)
        p.frame_src(*default_csp_values.split)
        p.child_src(*default_csp_values.split)
      end
    end

    it { is_expected.to include("script-src #{default_csp_values} 'unsafe-eval' #{cookielaw_url} #{onetrust_url} #{google_tag_manager_url}") }
    it { is_expected.to include("frame-src #{default_csp_values}") }
    it { is_expected.to include("child-src #{default_csp_values}") }
    it { is_expected.to include("connect-src #{cookielaw_url} #{onetrust_url} #{google_analytics_url} #{google_analytics_google_url} #{google_tag_manager_url}") }
    it { is_expected.to include("img-src #{google_analytics_url} #{google_tag_manager_url}") }
  end

  context 'when just a default CSP config exists' do
    let(:csp) do
      ActionDispatch::ContentSecurityPolicy.new do |p|
        p.default_src(*default_csp_values.split)
      end
    end

    it { is_expected.to include("default-src #{default_csp_values}") }
    it { is_expected.to include("script-src #{default_csp_values} 'unsafe-eval' #{cookielaw_url} #{onetrust_url} #{google_tag_manager_url}") }
    it { is_expected.to include("img-src #{default_csp_values} #{google_analytics_url} #{google_tag_manager_url}") }
    it { is_expected.to include("connect-src #{default_csp_values} localhost #{cookielaw_url} #{onetrust_url} #{google_analytics_url} #{google_analytics_google_url} #{google_tag_manager_url}") }
  end
end
