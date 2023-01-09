# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard merge requests', feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:page_path) { merge_requests_dashboard_path }

  it_behaves_like 'dashboard ultimate trial callout'
end
