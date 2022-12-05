# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard issues', feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:page_path) { issues_dashboard_path }

  it_behaves_like 'dashboard ultimate trial callout'
end
