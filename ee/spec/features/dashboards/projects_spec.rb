# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard projects', feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:page_path) { dashboard_projects_path }

  it_behaves_like 'dashboard ultimate trial callout'
end
