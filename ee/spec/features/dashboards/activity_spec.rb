# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard activity', feature_category: :user_profile do
  let(:user) { create(:user) }
  let(:page_path) { activity_dashboard_path }

  it_behaves_like 'dashboard ultimate trial callout'
end
