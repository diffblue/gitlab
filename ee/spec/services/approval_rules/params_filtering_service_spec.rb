# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::ParamsFilteringService do
  let(:service) { described_class.new(merge_request, user, params) }
  let(:project_member) { create(:user) }
  let(:outsider) { create(:user) }
  let(:accessible_group) { create(:group, :private) }
  let(:accessible_subgroup) { create(:group, :private, parent: accessible_group) }
  let(:inaccessible_group) { create(:group, :private) }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  describe '#execute' do
    before do
      project.add_maintainer(user)
      project.add_reporter(project_member)

      accessible_group.add_developer(user)
    end

    shared_examples_for('assigning users and groups') do
      before do
        allow(Ability).to receive(:allowed?).and_call_original

        allow(Ability)
          .to receive(:allowed?)
          .with(user, :update_approvers, merge_request)
          .and_return(can_update_approvers?)
      end

      context 'user can update approvers' do
        let(:can_update_approvers?) { true }

        it 'only assigns eligible users and groups' do
          params = service.execute

          rule1 = params[:approval_rules_attributes].first

          expect(rule1[:user_ids]).to contain_exactly(project_member.id)

          rule2 = params[:approval_rules_attributes].last
          expected_group_ids = expected_groups.map(&:id)

          expect(rule2[:user_ids]).to be_empty
          expect(rule2[:group_ids]).to contain_exactly(*expected_group_ids)
        end
      end

      context 'user cannot update approvers' do
        let(:can_update_approvers?) { false }

        it 'deletes the approval_rules_attributes from params' do
          expect(service.execute).not_to have_key(:approval_rules_attributes)
        end
      end
    end

    context 'create' do
      let(:merge_request) { build(:merge_request, target_project: project, source_project: project) }
      let(:params) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master',
          force_remove_source_branch: '1',
          approval_rules_attributes: approval_rules_attributes
        }
      end

      it_behaves_like 'assigning users and groups' do
        let(:approval_rules_attributes) do
          [
            { name: 'foo', user_ids: [project_member.id, outsider.id] },
            { name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, accessible_subgroup.id, inaccessible_group.id] }
          ]
        end

        let(:expected_groups) { [accessible_group, accessible_subgroup] }
      end

      # When a project approval rule is genuinely empty, it should not be converted
      # an any_approver rule
      context 'empty project approval rule' do
        let(:approval_rules_attributes) { [{ name: 'Foo', user_ids: [], group_ids: [] }] }

        it 'adds empty rule', :aggregate_failures do
          rules = service.execute[:approval_rules_attributes]

          expect(rules.size).to eq(1)
          expect(rules[0]['name']).to eq('Foo')
          expect(rules[0]['user_ids']).to be_empty
          expect(rules[0]['group_ids']).to be_empty
          expect(rules[0].key?('rule_type')).to be_falsy
        end
      end

      context 'inapplicable user defined rules' do
        let!(:source_rule) { create(:approval_project_rule, project: project) }
        let!(:another_source_rule) { create(:approval_project_rule, project: project) }
        let(:protected_branch) { create(:protected_branch, project: project, name: 'stable-*') }

        let(:approval_rules_attributes) do
          [
            { name: another_source_rule.name, approval_project_rule_id: another_source_rule.id, user_ids: [project_member.id, outsider.id] }
          ]
        end

        before do
          source_rule.update!(protected_branches: [protected_branch])
        end

        context 'when multiple_approval_rules feature is available' do
          before do
            stub_licensed_features(multiple_approval_rules: true)
          end

          it 'adds inapplicable user defined rules' do
            params = service.execute
            approval_rules_attrs = params[:approval_rules_attributes]

            aggregate_failures do
              expect(approval_rules_attrs.size).to eq(2)

              expect(approval_rules_attrs.first).to include(
                name: another_source_rule.name,
                approval_project_rule_id: another_source_rule.id
              )

              expect(approval_rules_attrs.last).to include(
                name: source_rule.name,
                approval_project_rule_id: source_rule.id,
                user_ids: source_rule.user_ids,
                group_ids: source_rule.group_ids,
                approvals_required: source_rule.approvals_required,
                rule_type: source_rule.rule_type
              )
            end
          end
        end

        context 'when multiple_approval_rules feature is not available' do
          before do
            stub_licensed_features(multiple_approval_rules: false)
          end

          it 'does not add inapplicable user defined rules' do
            params = service.execute
            approval_rules_attrs = params[:approval_rules_attributes]

            aggregate_failures do
              expect(approval_rules_attrs.size).to eq(1)
              expect(approval_rules_attrs.first).to include(
                name: another_source_rule.name,
                approval_project_rule_id: another_source_rule.id
              )
            end
          end
        end
      end

      context 'any approver rule' do
        let(:can_update_approvers?) { true }
        let(:approval_rules_attributes) do
          [
            { user_ids: [], group_ids: [], name: '' }
          ]
        end

        it 'sets rule type for the rules attributes' do
          params = service.execute
          rule = params[:approval_rules_attributes].first

          expect(rule[:rule_type]).to eq(:any_approver)
          expect(rule[:name]).to eq('All Members')
        end
      end

      # A test case for https://gitlab.com/gitlab-org/gitlab/-/issues/208978#note_353379792
      # Approval project rules with any_approver type have groups, but they shouldn't
      context 'any approver rule from a project rule' do
        let(:can_update_approvers?) { true }
        let(:approval_rules_attributes) do
          [
            { user_ids: [""], group_ids: [""], approval_project_rule_id: approval_rule.id }
          ]
        end

        context 'and the project rule has hidden groups' do
          let(:approval_rule) do
            create(:approval_project_rule, project: project, rule_type: :any_approver).tap do |rule|
              rule.groups << create(:group, :private)
            end
          end

          it 'sets rule type for the rules attributes' do
            params = service.execute
            rule = params[:approval_rules_attributes].first

            expect(rule[:rule_type]).to eq(:any_approver)
            expect(rule[:name]).to eq('All Members')
          end
        end
      end
    end

    context 'update' do
      let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
      let(:existing_private_group) { create(:group, :private) }
      let!(:rule1) { create(:approval_merge_request_rule, merge_request: merge_request, users: [create(:user)]) }
      let!(:rule2) { create(:approval_merge_request_rule, merge_request: merge_request, groups: [existing_private_group]) }

      it_behaves_like 'assigning users and groups' do
        let(:params) do
          {
            approval_rules_attributes: [
              { id: rule1.id, name: 'foo', user_ids: [project_member.id, outsider.id] },
              { id: rule2.id, name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, inaccessible_group.id] }
            ]
          }
        end

        let(:expected_groups) { [accessible_group, existing_private_group] }
      end

      context 'inapplicable user defined rules' do
        let!(:source_rule) { create(:approval_project_rule, project: project) }
        let(:protected_branch) { create(:protected_branch, project: project, name: 'stable-*') }
        let(:approval_rules_attrs) { service.execute[:approval_rules_attributes] }

        let(:params) do
          {
            approval_rules_attributes: [
              { id: rule1.id, name: 'foo', user_ids: [project_member.id, outsider.id] }
            ]
          }
        end

        before do
          source_rule.update!(protected_branches: [protected_branch])
        end

        it 'does not add inapplicable user defined rules' do
          aggregate_failures do
            expect(approval_rules_attrs.size).to eq(1)
            expect(approval_rules_attrs.first[:name]).to eq('foo')
          end
        end

        context 'when reset_approval_rules_to_defaults is true' do
          let(:params) do
            {
              approval_rules_attributes: [
                { id: rule1.id, name: 'foo', user_ids: [project_member.id, outsider.id] }
              ],
              reset_approval_rules_to_defaults: true
            }
          end

          context 'when multiple_approval_rules feature is available' do
            before do
              stub_licensed_features(multiple_approval_rules: true)
            end

            it 'adds inapplicable user defined rules' do
              aggregate_failures do
                expect(approval_rules_attrs.size).to eq(2)

                expect(approval_rules_attrs.first).to include(
                  id: rule1.id,
                  name: 'foo'
                )

                expect(approval_rules_attrs.last).to include(
                  name: source_rule.name,
                  approval_project_rule_id: source_rule.id,
                  user_ids: source_rule.user_ids,
                  group_ids: source_rule.group_ids,
                  approvals_required: source_rule.approvals_required,
                  rule_type: source_rule.rule_type
                )
              end
            end
          end

          context 'when multiple_approval_rules feature is not available' do
            before do
              stub_licensed_features(multiple_approval_rules: false)
            end

            it 'does not add inapplicable user defined rules' do
              aggregate_failures do
                expect(approval_rules_attrs.size).to eq(1)
                expect(approval_rules_attrs.first).to include(
                  id: rule1.id,
                  name: 'foo'
                )
              end
            end
          end
        end
      end

      context 'with remove_hidden_groups being true' do
        it_behaves_like 'assigning users and groups' do
          let(:params) do
            {
              approval_rules_attributes: [
                { id: rule1.id, name: 'foo', user_ids: [project_member.id, outsider.id] },
                { id: rule2.id, name: 'bar', user_ids: [outsider.id], group_ids: [accessible_group.id, inaccessible_group.id], remove_hidden_groups: true }
              ]
            }
          end

          let(:expected_groups) { [accessible_group] }
        end
      end
    end
  end
end
