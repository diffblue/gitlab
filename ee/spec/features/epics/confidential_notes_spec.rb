# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Confidential notes on epics", :js, feature_category: :portfolio_management do
  before do
    stub_licensed_features(epics: true)
  end

  it_behaves_like 'confidential notes on issuables' do
    let_it_be(:issuable_parent) { create(:group) }
    let_it_be(:issuable) { create(:epic, group: issuable_parent) }
    let_it_be(:user) { create(:user) }

    let(:issuable_path) { group_epic_path(issuable_parent, issuable) }
  end
end
