# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::IssuesMenu do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  describe '#render?' do
    let_it_be_with_refind(:project) { create(:project, has_external_issue_tracker: true) }
    let_it_be(:jira) { create(:jira_integration, project: project, project_key: 'GL') }

    let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, jira_issues_integration: jira_issues_integration) }
    let(:jira_issues_integration) { true }

    subject { described_class.new(context).render? }

    context 'when user cannot read issues and Jira is not enabled' do
      let(:user) { nil }
      let(:jira_issues_integration) { false }

      it { is_expected.to eq(false) }
    end

    context 'when user cannot read issues but Jira is enabled' do
      let(:user) { nil }

      it { is_expected.to eq(true) }
    end

    context 'when Jira is not enabled but user can read issues' do
      let(:jira_issues_integration) { false }

      it { is_expected.to eq(true) }
    end
  end

  describe 'Iterations' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }

    subject { described_class.new(context).renderable_items.index { |e| e.item_id == :iterations } }

    context 'when licensed feature iterations is not enabled' do
      it 'does not include iterations menu item' do
        stub_licensed_features(iterations: false)

        is_expected.to be_nil
      end
    end

    context 'when licensed feature iterations is enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      context 'when user can read iterations' do
        before do
          group.add_owner(user)
        end

        it 'includes iterations menu item' do
          is_expected.to be_present
        end

        context 'when project is namespaced to a user' do
          let(:project) { build(:project, namespace: user.namespace) }

          it 'does not include iterations menu item' do
            is_expected.to be_nil
          end
        end
      end

      context 'when user cannot read iterations' do
        let(:user) { nil }

        it 'does not include iterations menu item' do
          is_expected.to be_nil
        end
      end
    end
  end

  describe 'Requirements' do
    subject { described_class.new(context).renderable_items.any? { |e| e.item_id == :requirements } }

    context 'when licensed feature requirements is not enabled' do
      it 'does not include requirements menu item' do
        stub_licensed_features(requirements: false)

        is_expected.to be_falsy
      end
    end

    context 'when licensed feature requirements is enabled' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when user can read requirements' do
        it 'includes requirements menu item' do
          is_expected.to be_truthy
        end
      end

      context 'when user cannot read requirements' do
        let(:user) { nil }

        it 'does not include requirements menu item' do
          is_expected.to be_falsy
        end
      end
    end
  end

  describe 'Jira issues' do
    let_it_be_with_refind(:project) { create(:project, has_external_issue_tracker: true) }

    let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, jira_issues_integration: jira_issues_integration) }
    let(:jira_issues_integration) { false }

    subject { described_class.new(context) }

    context 'when issue tracker is not Jira' do
      it 'does not include Jira issues menu items' do
        create(:custom_issue_tracker_integration, active: true, project: project, project_url: 'http://test.com')

        expect(subject.show_jira_menu_items?).to eq(false)
        expect(subject.renderable_items.any? { |e| e.item_id == :jira_issue_list }).to eq(false)
      end
    end

    context 'when issue tracker is Jira' do
      let_it_be(:jira) { create(:jira_integration, project: project, project_key: 'GL') }

      context 'when issues integration is disabled' do
        it 'does not include Jira issues menu items' do
          expect(subject.show_jira_menu_items?).to eq(false)
          expect(subject.renderable_items.any? { |e| e.item_id == :jira_issue_list }).to eq(false)
        end
      end

      context 'when issues integration is enabled' do
        let(:jira_issues_integration) { true }

        it 'includes Jira issues menu items' do
          expect(subject.show_jira_menu_items?).to eq(true)
          expect(subject.renderable_items.any? { |e| e.item_id == :jira_issue_list }).to eq(true)
          expect(subject.renderable_items.any? { |e| e.item_id == :jira_external_link }).to eq(true)
        end
      end
    end
  end

  describe 'Zentao issues' do
    let(:project) { create(:project, has_external_issue_tracker: true) }
    let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }
    let(:zentao_integration) { create(:zentao_integration, project: project) }

    subject { described_class.new(context) }

    context 'when Zentao integration is enabled' do
      before do
        stub_licensed_features(zentao_issues_integration: true)
        zentao_integration.update!(active: true)
      end

      context 'when Issues feature is enabled' do
        before do
          allow(project).to receive(:issues_enabled?).and_return(true)
        end

        it 'includes Zentao issues menu items' do
          expect(subject.show_zentao_menu_items?).to eq(true)
          expect(subject.renderable_items.any? { |e| e.item_id == :zentao_issue_list }).to eq(true)
        end
      end

      context 'when Issues feature is disabled' do
        before do
          allow(project).to receive(:issues_enabled?).and_return(false)
        end

        it 'includes Zentao issues menu items' do
          expect(subject.show_zentao_menu_items?).to eq(true)
          expect(subject.renderable_items.any? { |e| e.item_id == :zentao_issue_list }).to eq(true)
        end
      end
    end

    context 'when Zentao integration is disabled' do
      before do
        stub_licensed_features(zentao_issues_integration: false)
      end

      context 'when Issues feature is disabled' do
        before do
          allow(project).to receive(:issues_enabled?).and_return(false)
        end

        it 'does not include Zentao issues menu items' do
          expect(subject.show_zentao_menu_items?).to eq(false)
          expect(subject.renderable_items.any? { |e| e.item_id == :zentao_issue_list }).to eq(false)
        end
      end
    end
  end
end
