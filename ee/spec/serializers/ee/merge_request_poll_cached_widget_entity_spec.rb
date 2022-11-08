# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPollCachedWidgetEntity do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_reload(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:user) { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  subject { described_class.new(resource, request: request).as_json }

  it 'includes policy violation status' do
    is_expected.to include(:policy_violation)
  end

  context 'jira_associations' do
    context 'when feature is available' do
      let_it_be(:jira_integration) { create(:jira_integration, project: project, active: true) }

      before do
        stub_licensed_features(jira_issues_integration: true, jira_issue_association_enforcement: true)
      end

      it { is_expected.to include(:jira_associations) }

      shared_examples 'contains the issue key specified in MR title / description' do
        context 'when Jira issue is provided in MR title' do
          let(:issue_key) { 'SIGNUP-1234' }

          before do
            resource.update!(title: "Fixes sign up issue #{issue_key}")
          end

          it { expect(subject[:jira_associations][:issue_keys]).to contain_exactly(issue_key) }
        end

        context 'when Jira issue is provided in MR description' do
          let(:issue_key) { 'SECURITY-1234' }

          before do
            resource.update!(description: "Related to #{issue_key}")
          end

          it { expect(subject[:jira_associations][:issue_keys]).to contain_exactly(issue_key) }
        end
      end

      shared_examples 'when issue key is NOT specified in MR title / description' do
        before do
          resource.update!(title: "Fixes sign up issue", description: "Prevent spam sign ups by adding a rate limiter")
        end

        it { expect(subject[:jira_associations][:issue_keys]).to be_empty }
      end

      context 'when jira issue is required for merge' do
        before do
          project.create_project_setting(prevent_merge_without_jira_issue: true)
        end

        it { expect(subject[:jira_associations][:enforced]).to be_truthy }

        it_behaves_like 'contains the issue key specified in MR title / description'
        it_behaves_like 'when issue key is NOT specified in MR title / description'
      end

      context 'when jira issue is NOT required for merge' do
        before do
          project.create_project_setting(prevent_merge_without_jira_issue: false)
        end

        it { expect(subject[:jira_associations][:enforced]).to be_falsey }

        it_behaves_like 'contains the issue key specified in MR title / description'
        it_behaves_like 'when issue key is NOT specified in MR title / description'
      end
    end

    context 'when feature is NOT available' do
      using RSpec::Parameterized::TableSyntax

      where(licensed: [true, false])

      with_them do
        before do
          stub_licensed_features(jira_issue_association_enforcement: licensed)
        end

        it { is_expected.not_to include(:jira_associations) }
      end
    end
  end
end
