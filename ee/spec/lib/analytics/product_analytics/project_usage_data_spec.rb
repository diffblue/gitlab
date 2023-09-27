# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Analytics::ProductAnalytics::ProjectUsageData, feature_category: :product_analytics_visualization do
  let_it_be(:setting) { create(:project_setting, :with_product_analytics_configured) }
  let_it_be(:project) { create(:project, project_setting: setting) }
  let(:fetcher) { described_class.new(project_id: project.id) }

  describe '#events_stored_count' do
    context 'when querying the current time period' do
      before do
        stub_successful_request
      end

      subject { fetcher.events_stored_count }

      it { is_expected.to eq(39) }
    end

    context 'when querying a different time period' do
      before do
        stub_successful_request_with_date
      end

      subject { fetcher.events_stored_count(month: 4, year: 2021) }

      it { is_expected.to eq(12) }
    end
  end

  private

  def stub_successful_request
    stub_request(:get, %r{\Ahttp://test.com/usage/gitlab_project_\d+/\d{4}/\d+\z})
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(
        {
          status: 200, body: {
            period: {
              month: 9,
              year: 2023
            },
            project_id: "gitlab_project_27",
            result: 39
          }.to_json
        }, headers: {})
  end

  def stub_successful_request_with_date
    stub_request(:get, %r{\Ahttp://test.com/usage/gitlab_project_\d+/2021/4\z})
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(
        {
          status: 200, body: {
            period: {
              month: 4,
              year: 2021
            },
            project_id: "gitlab_project_27",
            result: 12
          }.to_json
        }, headers: {})
  end
end
