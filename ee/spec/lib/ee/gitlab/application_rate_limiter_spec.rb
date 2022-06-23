# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::ApplicationRateLimiter do
  describe '.rate_limits' do
    before do
      stub_application_setting(max_number_of_repository_downloads: 1)
      stub_application_setting(max_number_of_repository_downloads_within_time_period: 60)
    end

    subject(:rate_limits) { Gitlab::ApplicationRateLimiter.rate_limits }

    it 'includes values for unique_project_downloads' do
      values = rate_limits[:unique_project_downloads]
      expect(values[:threshold].call).to eq 1
      expect(values[:interval].call).to eq 60
    end
  end
end
