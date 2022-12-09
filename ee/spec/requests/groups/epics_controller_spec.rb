# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EpicsController, feature_category: :portfolio_management do
  let(:group) { create(:group, :private) }
  let(:epic) { create(:epic, group: group) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(epics: true)
    sign_in(user)
    group.add_developer(user)
  end

  describe 'GET #new' do
    it_behaves_like "observability csp policy", described_class do
      let(:tested_path) do
        new_group_epic_path(group)
      end
    end
  end

  describe 'GET #show' do
    it_behaves_like "observability csp policy", described_class do
      let(:tested_path) do
        group_epic_path(group, epic)
      end
    end
  end
end
