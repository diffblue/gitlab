# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::MigrateApproverToApprovalRules do
  def create_skip_sync(*args)
    build(*args) do |record|
      allow(record).to receive(:schedule_approval_migration)
      record.save!
    end
  end

  def create_member_in(member, *populate_in)
    if populate_in.include?(:old_schema)
      case member
      when User
        create_skip_sync(:approver, target_type: target_type, target_id: target.id, user_id: member.id)
      when Group
        create_skip_sync(:approver_group, target_type: target_type, target_id: target.id, group_id: member.id)
      end
    end

    if populate_in.include?(:new_schema)
      case member
      when User
        approval_rule.users << member
      when Group
        approval_rule.groups << member
      end
    end
  end

  context 'sync approval rule and its members' do
    shared_examples 'sync approval member' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:group1) { create(:group) }
      let(:group2) { create(:group) }

      context 'when member in old schema but not in new schema' do
        before do
          create_member_in(user1, :old_schema)
          create_member_in(group1, :old_schema)
        end

        it 'creates in new schema' do
          expect do
            described_class.new.perform(target_type, target.id)
          end.to change { approval_rule.users.count }.by(1)
            .and change { approval_rule.groups.count }.by(1)

          expect(target.approval_rules.regular.first).to eq(approval_rule)

          expect(approval_rule.users).to contain_exactly(user1)
          expect(approval_rule.groups).to contain_exactly(group1)
        end

        context 'when rule is not created yet' do
          let(:approval_rule) { nil }

          it 'creates rule in new schema' do
            described_class.new.perform(target_type, target.id)

            approval_rule = target.approval_rules.regular.first

            expect(approval_rule.approvals_required).to eq(2)
            expect(approval_rule.name).to eq('Default')

            expect(approval_rule.users).to contain_exactly(user1)
            expect(approval_rule.groups).to contain_exactly(group1)
          end
        end
      end

      context 'when member not in old schema but in new schema' do
        before do
          create_member_in(user1, :new_schema)
          create_member_in(user2, :old_schema, :new_schema)
          create_member_in(group1, :new_schema)
          create_member_in(group2, :old_schema, :new_schema)
        end

        it 'removes in new schema' do
          expect do
            described_class.new.perform(target_type, target.id)
          end.to change { approval_rule.users.count }.by(-1)
            .and change { approval_rule.groups.count }.by(-1)

          approval_rule = target.approval_rules.first

          expect(approval_rule.users).to contain_exactly(user2)
          expect(approval_rule.groups).to contain_exactly(group2)
        end
      end

      context 'when approver has user_id which no longer exists' do
        before do
          create_member_in(user1, :old_schema)
          create_member_in(user2, :old_schema)
          create_member_in(group1, :old_schema)
          create_member_in(group2, :old_schema)
        end

        it 'ignores broken reference when assigning' do
          User.where(id: user1).delete_all
          Group.where(id: group1).delete_all

          described_class.new.perform(target_type, target.id)

          approval_rule = target.approval_rules.first

          expect(approval_rule.users).to contain_exactly(user2)
          expect(approval_rule.groups).to contain_exactly(group2)
        end
      end
    end

    context 'merge request' do
      let(:target) do
        merge_request = build(:merge_request, approvals_before_merge: 2,
          skip_ensure_merge_request_diff: true)

        allow(merge_request).to receive(:update_any_approver_rule)

        merge_request.save!
        merge_request
      end

      let(:target_type) { 'MergeRequest' }
      let(:approval_rule) { create(:approval_merge_request_rule, merge_request: target) }

      it_behaves_like 'sync approval member'

      context 'when project rule is present' do
        let!(:project_rule) { create(:approval_project_rule, project: target.target_project) }

        it "sets MR rule's source to project rule without duplication" do
          user = create(:user)
          create_member_in(user, :old_schema)
          create_member_in(user, :old_schema)

          described_class.new.perform(target_type, target.id)

          expect(target.approval_rules.regular.first.approval_project_rule).to eq(project_rule)
        end
      end

      context 'when project rule is absent' do
        it "has MR rule's source as nil" do
          create_member_in(create(:user), :old_schema)

          described_class.new.perform(target_type, target.id)

          expect(target.approval_rules.regular.first.approval_project_rule).to eq(nil)
        end
      end

      context 'when approvals_before_merge is nil' do
        it "updates with project's approvals_required" do
          target.target_project.update!(approvals_before_merge: 3)
          target.update!(approvals_before_merge: nil)
          create_member_in(create(:user), :old_schema)

          described_class.new.perform(target_type, target.id)

          expect(target.approval_rules.regular.first.approvals_required).to eq(3)
        end
      end

      context 'when approvals_before_merge is too big' do
        it "caps at allowed maximum" do
          target.target_project.update!(approvals_before_merge: ::ApprovalRuleLike::APPROVALS_REQUIRED_MAX + 1)
          target.update!(approvals_before_merge: nil)
          create_member_in(create(:user), :old_schema)

          described_class.new.perform(target_type, target.id)

          expect(target.approval_rules.regular.first.approvals_required).to eq(::ApprovalRuleLike::APPROVALS_REQUIRED_MAX)
        end
      end

      context 'when approver is no longer overwritten' do
        before do
          create_member_in(create(:user), :new_schema)
          create_member_in(create(:group), :new_schema)
        end

        it 'removes rule' do
          expect do
            described_class.new.perform(target_type, target.id)
          end.to change { approval_rule.users.count }.by(-1)
            .and change { approval_rule.groups.count }.by(-1)

          expect(target.approval_rules.exists?(approval_rule.id)).to eq(false)
        end
      end

      describe '#sync_code_owners_with_approvers' do
        let(:owners) { create_list(:user, 2) }

        before do
          entry = double('code owner entry', users: owners)
          allow(::Gitlab::CodeOwners).to receive(:entries_for_merge_request).and_return([entry])
        end

        context 'when merge request is merged' do
          let(:target) { create(:merged_merge_request, :skip_diff_creation) }

          it 'does nothing' do
            expect do
              described_class.new.perform(target_type, target.id)
            end.not_to change { target.approval_rules.count }
          end
        end

        context 'when code owner rule does not exist' do
          it 'creates rule' do
            expect do
              described_class.new.perform(target_type, target.id)
            end.to change { target.approval_rules.count }.by(1)

            rule = target.approval_rules.first

            expect(rule.code_owner).to eq(true)
            expect(rule.users).to contain_exactly(*owners)
          end
        end

        context 'when code owner rule exists' do
          let!(:code_owner_rule) { create(:code_owner_rule, merge_request: target, users: [create(:user)]) }

          it 'reuses and updates existing rule' do
            expect do
              described_class.new.perform(target_type, target.id)
            end.not_to change { target.approval_rules.count }

            expect(code_owner_rule.reload.users).to contain_exactly(*owners)
          end

          context 'when there is no code owner' do
            let(:owners) { [] }

            it 'removes rule' do
              described_class.new.perform(target_type, target.id)

              expect(target.approval_rules.exists?(code_owner_rule.id)).to eq(false)
            end
          end
        end
      end
    end

    context 'project' do
      let(:target) do
        project = build(:project, approvals_before_merge: 2)

        allow(project).to receive(:update_any_approver_rule)

        project.save!
        project
      end

      let(:target_type) { 'Project' }
      let(:approval_rule) { create(:approval_project_rule, project: target) }

      it_behaves_like 'sync approval member'
    end
  end

  context 'when target is deleted' do
    let(:target) { create(:project) }
    let(:target_type) { 'Project' }

    it "does not err" do
      target.destroy!

      expect do
        described_class.new.perform(target_type, target.id)
      end.not_to raise_error
    end
  end

  context 'when project has no repository' do
    let(:project_without_repository) { create(:project) }
    let(:target) { create(:merge_request, :skip_diff_creation, target_project: project_without_repository, source_project: project_without_repository) }
    let(:target_type) { 'MergeRequest' }

    it "does not err" do
      expect do
        described_class.new.perform(target_type, target.id)
      end.not_to raise_error
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
