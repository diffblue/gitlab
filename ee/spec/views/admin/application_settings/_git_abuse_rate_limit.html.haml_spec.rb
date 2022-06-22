# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_git_abuse_rate_limit' do
  let_it_be(:admin) { create(:admin) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded_by_default) { true }
  end

  describe 'git abuse rate limit settings' do
    before do
      stub_licensed_features(git_abuse_rate_limit: true)
      stub_feature_flags(git_abuse_rate_limit_feature_flag: true)
    end

    context 'when page loads' do
      let(:application_setting) { build(:application_setting) }

      it 'renders the section and input fields' do
        render

        expect(rendered).to have_selector('[data-testid="git-abuse-rate-limit-settings"]')
        expect(rendered).to have_field(s_('AdminSettings|Number of repositories'))
        expect(rendered).to have_field(s_('AdminSettings|Reporting time period (seconds)'))
      end
    end

    context 'when data is saved in the database' do
      let(:application_setting) do
        build(:application_setting,
              max_number_of_repository_downloads: 10,
              max_number_of_repository_downloads_within_time_period: 100
             )
      end

      it 'renders the input fields pre-populated with data' do
        render

        expect(rendered).to have_selector('[data-testid="git-abuse-rate-limit-settings"]')
        expect(rendered).to have_field(s_('AdminSettings|Number of repositories'), with: 10)
        expect(rendered).to have_field(s_('AdminSettings|Reporting time period (seconds)'), with: 100)
      end
    end
  end
end
