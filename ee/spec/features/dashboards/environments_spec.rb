# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments dashboard', :js, feature_category: :shared do
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(operations_dashboard: true)
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :operations_environments_path,
    :environments_dashboard
end
