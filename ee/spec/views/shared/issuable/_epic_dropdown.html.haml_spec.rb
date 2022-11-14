# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/issuable/_epic_dropdown.html.haml' do
  it_behaves_like 'issuable bulk dropdown', 'shared/issuable/epic_dropdown' do
    let(:feature_id) { :epics }
    let(:input_selector) { 'input#issue_epic_id[name="update[epic_id]"]' }
    let(:root_selector) { ".js-epic-dropdown-root[data-group-path=\"#{parent.full_path}\"]" }
  end
end
