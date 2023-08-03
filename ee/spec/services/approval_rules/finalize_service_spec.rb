# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::FinalizeService do
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe '#execute' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:group1_user) { create(:user) }
    let!(:group2_user) { create(:user) }
    let!(:approval1) { create(:approval, merge_request: merge_request, user: user1) }
    let!(:approval2) { create(:approval, merge_request: merge_request, user: user3) }
    let!(:approval3) { create(:approval, merge_request: merge_request, user: group1_user) }
    let!(:approval4) { create(:approval, merge_request: merge_request, user: group2_user) }
    let!(:project_rule) { create(:approval_project_rule, project: project, name: 'foo', approvals_required: 12) }

    subject { described_class.new(merge_request) }

    before do
      group1.add_guest(group1_user)
      group2.add_guest(group2_user)

      project_rule.users = [user1, user2]
      project_rule.groups << group1
    end

    shared_examples 'skipping when unmerged' do
      it 'does nothing if unmerged' do
        expect do
          subject.execute
        end.not_to change { ApprovalMergeRequestRule.count }
      end
    end

    context 'when there is no merge request rules' do
      it_behaves_like 'skipping when unmerged'

      context 'when merged' do
        let(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        before do
          merge_request.approval_rules.code_owner.create!(name: 'Code Owner', rule_type: :code_owner)
        end

        context 'when copying the rules' do
          let!(:any_approver) { create(:approval_project_rule, project: project, name: 'hallo', approvals_required: 45, rule_type: :any_approver) }
          let!(:protected_branch) { create(:approval_project_rules_protected_branch, approval_project_rule: protected_rule) }
          let(:protected_rule) { create(:approval_project_rule, project: project, name: 'other_branch', approvals_required: 32) }
          let!(:reporter_rule) { create(:approval_project_rule, :license_scanning, project: project, name: 'reporter_branch', approvals_required: 21) }

          let(:expected_rules) do
            {
              regular: {
                required: 12,
                name: "foo",
                users: [user1, user2, group1_user],
                groups: [group1],
                approvers: [user1, group1_user],
                rule_type: 'regular',
                report_type: nil
              },
              code_owner: {
                required: 0,
                name: "Code Owner",
                users: [],
                groups: [],
                approvers: [],
                rule_type: 'code_owner',
                report_type: nil
              },
              any_approver: {
                required: 45,
                name: "hallo",
                users: [],
                groups: [],
                approvers: [user1, user3, group1_user, group2_user],
                rule_type: 'any_approver',
                report_type: nil
              },
              report_approver: {
                required: 21,
                name: "reporter_branch",
                users: [],
                groups: [],
                approvers: [],
                rule_type: 'report_approver',
                report_type: 'license_scanning'
              },
              non_applicable: {
                required: 32,
                name: "other_branch",
                users: [],
                groups: [],
                approvers: [],
                rule_type: 'regular'
              }
            }
          end

          context 'when copy_additional_properties_approval_rules is on' do
            context 'when one of the rules is invalid with the new attributes' do
              it 'retries with simplified attributes' do
                project.approval_rules.each(&:destroy!)
                project_rule = create(:approval_project_rule, :license_scanning, project: project, name: 'reporter_branch', approvals_required: 21)
                project.approval_rules.reload
                rule_double = instance_double(
                  ApprovalMergeRequestRule,
                  valid?: false,
                  errors: ActiveModel::Errors.new(project_rule))

                rules = merge_request.approval_rules
                allow(merge_request).to receive(:approval_rules).and_return(rules)
                expect(rules).to receive(:new).with(hash_including('approvals_required', 'name', 'rule_type', 'report_type')).and_return(rule_double)
                expect(rules).to receive(:create!).with(hash_not_including('rule_type', 'report_type')).and_call_original
                expect(Gitlab::AppLogger).to receive(:debug)

                expect do
                  subject.execute
                end.to change { ApprovalMergeRequestRule.count }.by(1)

                rule = merge_request.approval_rules.find_by(name: 'reporter_branch')

                expect(rule.approvals_required).to eq(21)
                expect(rule.report_type).to eq(nil)
                expect(rule.rule_type).to eq('regular')
              end
            end

            it 'copies the expected rules with expected params' do
              expect do
                subject.execute
              end.to change { ApprovalMergeRequestRule.count }.by(4)

              expect(merge_request.approval_rules.size).to be(5)

              expected_rules.each do |_key, hash|
                rule = merge_request.approval_rules.find_by(name: hash[:name])

                expect(rule).to be_truthy
                expect(rule.rule_type).to eq(hash[:rule_type])
                expect(rule.approvals_required).to eq(hash[:required])
                expect(rule.report_type).to eq(hash[:report_type])
                expect(rule.users).to contain_exactly(*hash[:users])
                expect(rule.groups).to contain_exactly(*hash[:groups])
                expect(rule.approved_approvers).to contain_exactly(*hash[:approvers])
              end
            end
          end

          context 'when copy_additional_properties_approval_rules is off' do
            it 'copies the expected rules with expected params - including non-applicable' do
              stub_feature_flags(copy_additional_properties_approval_rules: false)

              expected_rules[:regular][:rule_type] = 'regular'
              expected_rules[:any_approver][:rule_type] = 'regular'
              expected_rules[:any_approver][:approvers] = []
              expected_rules[:report_approver][:rule_type] = 'regular'

              expect do
                subject.execute
              end.to change { ApprovalMergeRequestRule.count }.by(4)

              expect(merge_request.approval_rules.size).to be(5)

              expected_rules.each do |_key, hash|
                rule = merge_request.approval_rules.find_by(name: hash[:name])

                expect(rule).to be_truthy
                expect(rule.rule_type).to eq(hash[:rule_type])
                expect(rule.report_type).to be_nil
                expect(rule.approvals_required).to eq(hash[:required])
                expect(rule.users).to contain_exactly(*hash[:users])
                expect(rule.groups).to contain_exactly(*hash[:groups])
                expect(rule.approved_approvers).to contain_exactly(*hash[:approvers])
              end
            end
          end
        end

        shared_examples 'idempotent approval tests' do |rule_type|
          before do
            project_rule.destroy!

            rule = create(:approval_project_rule, project: project, name: 'another rule', approvals_required: 2, rule_type: rule_type)
            rule.users = [user1]
            rule.groups << group1

            # Emulate merge requests approval rules synced with project rule
            mr_rule = create(:approval_merge_request_rule, merge_request: merge_request, name: rule.name, approvals_required: 2, rule_type: rule_type)
            mr_rule.users = rule.users
            mr_rule.groups = rule.groups
          end

          it 'does not create a new rule if one exists' do
            expect do
              2.times { subject.execute }
            end.not_to change { ApprovalMergeRequestRule.count }
          end
        end

        ApprovalProjectRule.rule_types.except(:code_owner, :report_approver).each do |rule_type, _value|
          it_behaves_like 'idempotent approval tests', rule_type
        end
      end
    end

    context 'when there is a regular merge request rule' do
      before do
        rule = create(:approval_merge_request_rule, merge_request: merge_request, name: 'bar', approvals_required: 32)
        rule.users = [user2, user3]
        rule.groups << group2
      end

      it_behaves_like 'skipping when unmerged'

      context 'when merged' do
        let(:merge_request) { create(:merged_merge_request, source_project: project, target_project: project) }

        it 'does not copy project rules, and updates approval mapping with MR rules' do
          allow(subject).to receive(:copy_project_approval_rules)

          expect do
            subject.execute
          end.not_to change { ApprovalMergeRequestRule.count }

          rule = merge_request.approval_rules.regular.first

          expect(rule.name).to eq('bar')
          expect(rule.approvals_required).to eq(32)
          expect(rule.users).to contain_exactly(user2, user3, group2_user)
          expect(rule.groups).to contain_exactly(group2)
          expect(rule.rule_type).not_to be_nil

          expect(rule.approved_approvers).to contain_exactly(user3, group2_user)
          expect(subject).not_to have_received(:copy_project_approval_rules)
        end

        # Test for https://gitlab.com/gitlab-org/gitlab/issues/13488
        it 'gracefully merges duplicate users' do
          group2.add_developer(user2)

          expect do
            subject.execute
          end.not_to change { ApprovalMergeRequestRule.count }

          rule = merge_request.approval_rules.regular.first

          expect(rule.name).to eq('bar')
          expect(rule.users).to contain_exactly(user2, user3, group2_user)
        end
      end
    end
  end
end
