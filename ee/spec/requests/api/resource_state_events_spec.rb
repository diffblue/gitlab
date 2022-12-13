# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ResourceStateEvents, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }

  before do
    parent.add_developer(user)
  end

  context 'when eventable is an Epic' do
    before do
      parent.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'resource_state_events API', 'groups', 'epics', 'id' do
      let(:parent) { create(:group, :public) }
      let(:eventable) { create(:epic, group: parent, author: user) }
    end
  end
end
