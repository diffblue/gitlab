# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePolicy do
  let_it_be(:owner) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, group: namespace) }
  let_it_be(:issue) { create(:issue, project: project) }
  let(:user) { owner }

  subject { described_class.new(user, issue) }

  before do
    namespace.add_owner(owner)

    allow(issue).to receive(:project).and_return(project)
    allow(project).to receive(:namespace).and_return(namespace)
    allow(project).to receive(:design_management_enabled?).and_return true
  end

  it { is_expected.to be_allowed(:create_issue, :update_issue, :read_issue_iid, :reopen_issue, :create_design, :create_note) }

  describe 'summarize_notes' do
    before do
      stub_licensed_features(summarize_notes: true)
      stub_feature_flags(summarize_comments: project)
    end

    context 'when a member' do
      context 'on a public project' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it { is_expected.to be_allowed(:summarize_notes) }

        context 'when license is not set' do
          before do
            stub_licensed_features(summarize_notes: false)
          end

          it { is_expected.to be_disallowed(:summarize_notes) }
        end

        context 'when feature flag is not set' do
          before do
            stub_feature_flags(summarize_comments: false)
          end

          it { is_expected.to be_disallowed(:summarize_notes) }
        end

        context 'on confidential issue' do
          let_it_be(:issue) { create(:issue, :confidential, project: project) }

          it { is_expected.to be_disallowed(:summarize_notes) }
        end
      end

      context 'on a private project' do
        let_it_be(:project) { create(:project, :private) }

        it { is_expected.to be_disallowed(:summarize_notes) }
      end

      context 'on confidential issue' do
        let_it_be(:issue) { create(:issue, :confidential, project: project) }

        it { is_expected.to be_disallowed(:summarize_notes) }
      end
    end

    context 'when not a member' do
      let_it_be(:user) { create(:user) }

      context 'on a public project' do
        let_it_be(:project) { create(:project, :public) }

        it { is_expected.to be_disallowed(:summarize_notes) }
      end

      context 'on a private project' do
        it { is_expected.to be_disallowed(:summarize_notes) }
      end
    end
  end
end
