# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::ComplianceManagement::MergeRequestApprovalSettings::Resolver do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }

  let(:project) { build(:project, group: group) }
  let(:namespace_project) { build(:project) }

  before(:all) do
    group.create_group_merge_request_approval_setting
  end

  it 'is initialized' do
    resolver = described_class.new(group)

    expect(resolver).not_to be_nil
  end

  shared_examples 'a MR approval setting' do
    it 'has the correct value' do
      expect(object.value).to eq(value)
    end

    it 'has the correct locked status' do
      expect(object.locked).to eq(locked)
    end

    it 'has the correct inheritance' do
      expect(object.inherited_from).to eq(inherited_from)
    end
  end

  describe '#allow_author_approval' do
    where(:instance_prevents_approval, :group_allows_approval, :project_allows_approval, :value, :locked, :inherited_from) do
      # Cases where the project is nil
      true  | true  | nil | false | true  | :instance
      true  | false | nil | false | true  | :instance
      false | true  | nil | true  | false | nil
      false | false | nil | false | false | nil

      # Cases which do not include a group
      false | nil | true  | true  | false | nil
      false | nil | false | false | false | nil
      true  | nil | false | false | true  | :instance

      # Cases which include a project
      false | true  | true  | true  | false | nil
      false | false | true  | false | true  | :group
      true  | true  | true  | false | true  | :instance
      false | true  | false | false | false | nil
    end

    with_them do
      before do
        stub_ee_application_setting(prevent_merge_requests_author_approval: instance_prevents_approval)
        group.group_merge_request_approval_setting.update!(allow_author_approval: !!group_allows_approval)
        project.update!(merge_requests_author_approval: project_allows_approval)
      end

      let(:object) do
        if project_allows_approval.nil?
          described_class.new(group).allow_author_approval
        elsif group_allows_approval.nil?
          described_class.new(nil, project: project).allow_author_approval
        else
          described_class.new(group, project: project).allow_author_approval
        end
      end

      it_behaves_like 'a MR approval setting'
    end
  end

  describe '#allow_committer_approval' do
    where(:instance_prevents_approval, :group_allows_approval, :project_prevents_approval, :value, :locked, :inherited_from) do
      # Cases where the project is nil
      true  | true  | nil | false | true  | :instance
      true  | false | nil | false | true  | :instance
      false | true  | nil | true  | false | nil
      false | false | nil | false | false | nil

      # Cases which do not include a group
      false | nil | true  | false | false | nil
      true  | nil | false | false | true  | :instance

      # Cases which include a project
      false | true  | true  | false | false | nil
      false | false | false | false | true  | :group
      true  | true  | false | false | true  | :instance
    end

    with_them do
      before do
        stub_ee_application_setting(prevent_merge_requests_committers_approval: instance_prevents_approval)
        group.group_merge_request_approval_setting.update!(allow_committer_approval: !!group_allows_approval)
        project.update!(merge_requests_disable_committers_approval: project_prevents_approval)
      end

      let(:object) do
        if project_prevents_approval.nil?
          described_class.new(group).allow_committer_approval
        elsif group_allows_approval.nil?
          described_class.new(nil, project: project).allow_committer_approval
        else
          described_class.new(group, project: project).allow_committer_approval
        end
      end

      it_behaves_like 'a MR approval setting'
    end
  end

  describe '#allow_overrides_to_approver_list_per_merge_request' do
    where(:instance_prevents_approval, :group_allows_approval, :project_prevents_approval, :value, :locked, :inherited_from) do
      # Cases where the project is nil
      true  | true  | nil | false | true  | :instance
      true  | false | nil | false | true  | :instance
      false | true  | nil | true  | false | nil
      false | false | nil | false | false | nil

      # Cases which do not include a group
      false | nil | true  | false | false | nil
      true  | nil | false | false | true  | :instance

      # Cases which include a project
      false | true  | true  | false | false | nil
      false | false | false | false | true  | :group
      true  | true  | false | false | true  | :instance
    end

    with_them do
      before do
        stub_ee_application_setting(disable_overriding_approvers_per_merge_request: instance_prevents_approval)
        group.group_merge_request_approval_setting.update!(allow_overrides_to_approver_list_per_merge_request: !!group_allows_approval)
        project.update!(disable_overriding_approvers_per_merge_request: project_prevents_approval)
      end

      let(:object) do
        if project_prevents_approval.nil?
          described_class.new(group).allow_overrides_to_approver_list_per_merge_request
        elsif group_allows_approval.nil?
          described_class.new(nil, project: project).allow_overrides_to_approver_list_per_merge_request
        else
          described_class.new(group, project: project).allow_overrides_to_approver_list_per_merge_request
        end
      end

      it_behaves_like 'a MR approval setting'
    end
  end

  describe '#retain_approvals_on_push' do
    where(:group_retains_approvals, :project_resets_approvals, :value, :locked, :inherited_from) do
      true  | nil | true  | false | nil
      false | nil | false | false | nil

      # Cases which do not include a group
      nil | true  | false | false | nil
      nil | false | true  | false | nil

      # Cases with a project
      true  | false | true  | false | nil
      false | true  | false | true  | :group
      false | false | false | true  | :group
      true  | true  | false | false | nil
    end

    with_them do
      before do
        group.group_merge_request_approval_setting.update!(retain_approvals_on_push: !!group_retains_approvals)
        project.update!(reset_approvals_on_push: project_resets_approvals)
      end

      let(:object) do
        if project_resets_approvals.nil?
          described_class.new(group).retain_approvals_on_push
        elsif group_retains_approvals.nil?
          described_class.new(nil, project: project).retain_approvals_on_push
        else
          described_class.new(group, project: project).retain_approvals_on_push
        end
      end

      it_behaves_like 'a MR approval setting'
    end
  end

  describe '#require_password_to_approve' do
    where(:group_requires_password, :project_requires_password, :value, :locked, :inherited_from) do
      true  | nil | true  | false | nil
      false | nil | false | false | nil

      # Cases which do not include a group
      nil | true  | true  | false | nil
      nil | false | false | false | nil

      # Cases with a project
      true  | false | true  | true  | :group
      true  | true  | true  | true  | :group
      false | false | false | false | nil
      false | true  | true  | false | nil
    end

    with_them do
      before do
        group.group_merge_request_approval_setting.update!(require_password_to_approve: !!group_requires_password)
        project.update!(require_password_to_approve: project_requires_password)
      end

      let(:object) do
        if project_requires_password.nil?
          described_class.new(group).require_password_to_approve
        elsif group_requires_password.nil?
          described_class.new(nil, project: project).require_password_to_approve
        else
          described_class.new(group, project: project).require_password_to_approve
        end
      end

      it_behaves_like 'a MR approval setting'
    end
  end
end
