# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::RunnersController, feature_category: :runner_fleet do
  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#index' do
    it 'enables runner_performance_insights and runner_upgrade_management licensed feature' do
      is_expected.to receive(:push_licensed_feature).with(:runner_performance_insights)
      is_expected.to receive(:push_licensed_feature).with(:runner_upgrade_management)

      get :index
    end

    context 'when fetching runner releases is disabled' do
      before do
        stub_application_setting(update_runner_versions_enabled: false)
      end

      it 'enables only runner_performance_insights licensed feature' do
        is_expected.to receive(:push_licensed_feature).with(:runner_performance_insights)
        is_expected.not_to receive(:push_licensed_feature).with(:runner_upgrade_management)

        get :index
      end
    end
  end

  describe '#show' do
    it 'enables runner_upgrade_management, runner_maintenance_note licensed features' do
      is_expected.to receive(:push_licensed_feature).with(:runner_upgrade_management)
      is_expected.to receive(:push_licensed_feature).with(:runner_maintenance_note)

      get :show, params: { id: runner }
    end

    context 'when fetching runner releases is disabled' do
      before do
        stub_application_setting(update_runner_versions_enabled: false)
      end

      it 'enables only runner_maintenance_note licensed feature' do
        is_expected.to receive(:push_licensed_feature).with(:runner_maintenance_note)
        is_expected.not_to receive(:push_licensed_feature).with(:runner_upgrade_management)

        get :show, params: { id: runner }
      end
    end
  end

  describe '#edit' do
    it 'enables runner_maintenance_note licensed feature' do
      is_expected.to receive(:push_licensed_feature).with(:runner_maintenance_note)

      get :edit, params: { id: runner }
    end
  end
end
