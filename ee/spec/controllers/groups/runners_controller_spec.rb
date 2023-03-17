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

    context 'when fetching runner releases is disabled' do
      before do
        stub_application_setting(update_runner_versions_enabled: false)
      end

      it 'does not enable runner_upgrade_management_for_namespace licensed feature' do
        is_expected.not_to receive(:push_licensed_feature).with(:runner_upgrade_management_for_namespace)

        get :index, params: { group_id: group }
      end
    end
  end

  describe '#show' do
    let(:runner) { create(:ci_runner, :group, groups: [group]) }

    it 'enables runner_upgrade_management_for_namespace licensed feature' do
      is_expected.to receive(:push_licensed_feature).with(:runner_upgrade_management_for_namespace, group)

      get :show, params: { group_id: group, id: runner }
    end

    context 'when fetching runner releases is disabled' do
      before do
        stub_application_setting(update_runner_versions_enabled: false)
      end

      it 'does not enable runner_upgrade_management_for_namespace licensed feature' do
        is_expected.not_to receive(:push_licensed_feature).with(:runner_upgrade_management_for_namespace)

        get :show, params: { group_id: group, id: runner }
      end
    end
  end
end
