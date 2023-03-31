# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Security dashboard', :js, feature_category: :shared do
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :security_dashboard_path, :security_dashboard
end
