# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/issuable/_iterations_dropdown.html.haml' do
  it_behaves_like 'issuable bulk dropdown', 'shared/issuable/iterations_dropdown' do
    let(:feature_id) { :iterations }
    let(:input_selector) { 'input#issue_iteration_id[name="update[iteration_id]"]' }
    let(:root_selector) { ".js-iteration-dropdown-root[data-full-path=\"#{parent.full_path}\"]" }
  end
end
