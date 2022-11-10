# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/issuable/_health_status_dropdown.html.haml' do
  it_behaves_like 'issuable bulk dropdown', 'shared/issuable/health_status_dropdown' do
    let(:feature_id) { :issuable_health_status }
    let(:input_selector) { 'input#issue_health_status_value[name="update[health_status]"]' }
    let(:root_selector) { ".js-health-status-dropdown-root" }
  end
end
