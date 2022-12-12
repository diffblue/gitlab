# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RunnersController, feature_category: :runner_fleet do
  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:user) }

  before do
    group.add_owner(owner)
    sign_in(owner)
  end

  describe '#index' do
    it 'enables runner_upgrade_management_for_namespace licensed feature' do
      is_expected.to receive(:push_licensed_feature).with(:runner_upgrade_management_for_namespace, group)

      get :index, params: { group_id: group }
    end
  end

  describe '#show' do
    let(:runner) { create(:ci_runner, :group, groups: [group]) }

    it 'enables runner_upgrade_management_for_namespace licensed feature' do
      is_expected.to receive(:push_licensed_feature).with(:runner_upgrade_management_for_namespace, group)

      get :show, params: { group_id: group, id: runner }
    end
  end
end
