# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::SettingsMenu, feature_category: :navigation do
  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:show_promotions) { true }
  let(:show_discover_project_security) { true }
  let(:context) do
    Sidebars::Projects::Context.new(current_user: user, container: project, show_promotions: show_promotions,
      show_discover_project_security: show_discover_project_security)
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Analytics' do
      let(:item_id) { :analytics }

      it_behaves_like 'access rights checks'

      it 'is nil when combined_analytics_dashboards feature flag is disabled' do
        stub_feature_flags(combined_analytics_dashboards: false)

        expect(subject).to be_nil
      end
    end
  end
end
