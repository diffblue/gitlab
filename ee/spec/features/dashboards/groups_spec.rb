# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard groups', feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:page_path) { dashboard_groups_path }

  it_behaves_like 'dashboard ultimate trial callout'
end
