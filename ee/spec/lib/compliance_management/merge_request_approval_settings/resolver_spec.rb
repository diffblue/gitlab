# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::ComplianceManagement::MergeRequestApprovalSettings::Resolver do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }

  before(:all) do
    group.create_group_merge_request_approval_setting
  end

  it 'is initialized' do
    resolver = described_class.new(group)

    expect(resolver).not_to be_nil
  end

  shared_examples 'resolvable but has no instance setting' do
    where(:group_allows_approval, :value, :locked, :inherited_from) do
      true  | true  | false | nil
      false | false | false | nil
    end

    with_them do
      before do
        group.group_merge_request_approval_setting.update!(instance_method => group_allows_approval)
      end

      let(:object) { described_class.new(group).send(instance_method) }

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
  end

  shared_examples 'resolvable' do
    where(:instance_prevents_approval, :group_allows_approval, :value, :locked, :inherited_from) do
      true  | true  | false | true  | :instance
      true  | false | false | true  | :instance
      false | true  | true  | false | nil
      false | false | false | false | nil
    end

    with_them do
      before do
        stub_ee_application_setting(instance_flag => instance_prevents_approval)
        group.group_merge_request_approval_setting.update!(group_flag => group_allows_approval)
      end

      let(:object) { described_class.new(group).send(group_flag) }

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
  end

  describe '#allow_author_approval' do
    let(:instance_flag) { :prevent_merge_requests_author_approval }
    let(:group_flag) { :allow_author_approval }

    it_behaves_like 'resolvable'
  end

  describe '#allow_committer_approval' do
    let(:instance_flag) { :prevent_merge_requests_committers_approval }
    let(:group_flag) { :allow_committer_approval }

    it_behaves_like 'resolvable'
  end

  describe '#allow_overrides_to_approver_list_per_merge_request' do
    let(:instance_flag) { :disable_overriding_approvers_per_merge_request }
    let(:group_flag) { :allow_overrides_to_approver_list_per_merge_request }

    it_behaves_like 'resolvable'
  end

  describe '#retain_approvals_on_push' do
    let(:instance_method) { :retain_approvals_on_push }

    it_behaves_like 'resolvable but has no instance setting'
  end

  describe '#require_password_to_approve' do
    let(:instance_method) { :require_password_to_approve }

    it_behaves_like 'resolvable but has no instance setting'
  end
end
