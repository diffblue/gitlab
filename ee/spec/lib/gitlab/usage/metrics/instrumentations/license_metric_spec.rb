# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::LicenseMetric do
  let(:current_license) { ::License.current }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'trial?' } } do
    let(:expected_value) { current_license.trial? }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'license_id' } } do
    let(:expected_value) { current_license.license_id }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'expires_at' } } do
    let(:expected_value) { current_license.expires_at }
  end

  context 'when in FIPS mode', :fips_mode do
    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'md5' } } do
      let(:expected_value) { nil }
    end
  end

  context 'when not in FIPS mode' do
    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'md5' } } do
      let(:expected_value) { current_license.md5 }
    end
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'trial_ends_on' } } do
    let(:expected_value) { ::License.trial_ends_on }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'plan' } } do
    let(:expected_value) { current_license.plan }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'subscription_id' } } do
    let(:expected_value) { current_license.subscription_id }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'starts_at' } } do
    let(:expected_value) { current_license.starts_at }
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', options: { attribute: 'user_count' } } do
    let(:expected_value) { current_license.restricted_user_count }
  end
end
