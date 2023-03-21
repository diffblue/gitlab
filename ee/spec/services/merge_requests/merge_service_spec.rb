# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeService, feature_category: :source_code_management do
  include NamespaceStorageHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request, reload: true) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project: project, current_user: user, params: params) }
  let(:params) { { sha: merge_request.diff_head_sha, commit_message: 'Awesome message' } }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'project has exceeded size limit' do
      before do
        project.update_attribute(:repository_size_limit, 5)
        project.statistics.update!(repository_size: 8)
      end

      it 'persists the correct error message' do
        service.execute(merge_request)

        expect(merge_request.merge_error).to eq(
          'This merge request cannot be merged, ' \
          'because this repository has exceeded its size limit of 5 Bytes by 3 Bytes'
        )
      end
    end

    context 'when the namespace storage limit has been exceeded', :saas do
      let(:namespace) { project.namespace }

      before do
        create(:gitlab_subscription, :premium, namespace: namespace)
        create(:namespace_root_storage_statistics, namespace: namespace)
        enforce_namespace_storage_limit(namespace)
        set_storage_size_limit(namespace, megabytes: 4)
        set_used_storage(namespace, megabytes: 5)
      end

      it 'persists the correct error message' do
        service.execute(merge_request)

        expect(merge_request.merge_error).to include(
          'Your namespace storage is full. This merge request cannot be merged.'
        )
      end
    end

    context 'when the repository size limit has been exceeded, but the namespace storage limit has not', :saas do
      let(:namespace) { project.namespace }

      before do
        project.update_attribute(:repository_size_limit, 5)
        project.statistics.update!(repository_size: 6)
        create(:gitlab_subscription, :premium, namespace: namespace)
        create(:namespace_root_storage_statistics, namespace: namespace)
        enforce_namespace_storage_limit(namespace)
        set_storage_size_limit(namespace, megabytes: 10)
        set_used_storage(namespace, megabytes: 7)
      end

      it 'does not set an error message' do
        service.execute(merge_request)

        expect(merge_request.merge_error).to be_nil
      end
    end

    context 'when the namespace storage limit has been exceeded and the merge request is for a subgroup project', :saas do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }
      let(:project) { create(:project, :repository, group: subgroup) }
      let(:merge_request) { create(:merge_request, :simple, source_project: project) }

      before do
        create(:gitlab_subscription, :premium, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_storage_size_limit(group, megabytes: 6)
        set_used_storage(group, megabytes: 8)
      end

      it 'persists the correct error message' do
        service.execute(merge_request)

        expect(merge_request.merge_error).to include(
          'Your namespace storage is full. This merge request cannot be merged.'
        )
      end
    end

    context 'when the namespace is over the free user cap limit', :saas do
      let(:namespace) { create(:group_with_plan, :private, plan: :free_plan) }

      before do
        project.update!(namespace: namespace)
        stub_ee_application_setting(dashboard_limit_enabled: true)
      end

      it 'persists the correct error message' do
        service.execute(merge_request)

        expect(merge_request.merge_error).to match(/Your top-level group is over the user limit/)
      end
    end

    context 'when merge request rule exists' do
      let(:approver) { create(:user) }
      let!(:approval_rule) { create :approval_merge_request_rule, merge_request: merge_request, users: [approver] }
      let!(:approval) { create :approval, merge_request: merge_request, user: approver }

      it 'creates approved_approvers' do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
        merge_request.reload
        rule = merge_request.approval_rules.first

        expect(merge_request.merged?).to eq(true)
        expect(rule.approved_approvers).to contain_exactly(approver)
      end
    end

    context 'with jira issue enforcement' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:jira_integration) { create(:jira_integration) }

      subject do
        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      where(:prevent_merge, :issue_specified, :merged) do
        true  | true  | true
        true  | false | false
        false | true  | true
        false | false | true
      end

      with_them do
        before do
          allow(project).to receive(:jira_integration).and_return(jira_integration)
          allow(project).to receive(:prevent_merge_without_jira_issue?).and_return(prevent_merge)
          allow(Atlassian::JiraIssueKeyExtractor).to receive(:has_keys?)
            .with(merge_request.title, merge_request.description, custom_regex: merge_request.project.jira_integration.reference_pattern)
                                                       .and_return(issue_specified)
        end

        it 'sets the correct merged state and raises an error when applicable', :aggregate_failures do
          subject

          expect(merge_request.reload.merged?).to eq(merged)
          expect(merge_request.merge_error).to include('Before this can be merged, a Jira issue must be linked in the title or description') unless merged
        end
      end
    end
  end

  it_behaves_like 'merge validation hooks', persisted: true
end
