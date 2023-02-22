# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::UpdateApprovalRule, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request, reload: true) { create(:merge_request) }
  let_it_be(:rule) do
    create(:approval_merge_request_rule, name: "test-rule", merge_request: merge_request, approvals_required: 1)
  end

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let(:approvals_required) { 1 }
    let(:approval_rule_id) { rule.id }
    let(:name) { "test-rule" }
    let(:group_ids) { [] }
    let(:user_ids) { [] }
    let(:mutated_approval_rule) { subject[:approval_merge_request_rule] }
    let(:remove_hidden_groups) { false }

    subject do
      mutation.resolve(project_path: merge_request.project.full_path,
        iid: merge_request.iid,
        approvals_required: approvals_required,
        approval_rule_id: approval_rule_id,
        name: name,
        group_ids: group_ids,
        user_ids: user_ids,
        remove_hidden_groups: remove_hidden_groups)
    end

    before do
      merge_request.project.add_owner(user)
    end

    context 'when the user can update the approval_rules' do
      context 'with approval_required' do
        let(:approvals_required) { 2 }

        it 'succeeds' do
          expect(mutated_approval_rule.approvals_required).to eq(approvals_required)
        end
      end

      context 'with name' do
        let(:name) { "updated-name" }

        it 'succeeds' do
          expect(mutated_approval_rule.name).to eq(name)
        end
      end

      context 'with user_ids' do
        let(:another_user) { create(:user) }
        let(:user_ids) { [another_user.id] }

        context "when user is part of the project" do
          before do
            merge_request.project.add_developer(another_user)
          end

          it 'succeeds' do
            expect(mutated_approval_rule.users).to match_array([another_user])
          end
        end

        context "when user is not part of the project" do
          it 'fails' do
            expect(mutated_approval_rule.users).to match_array([])
          end
        end
      end

      context 'with group_ids' do
        let(:group) { create(:group, :public) }
        let(:group_ids) { [group.id] }

        it 'succeeds' do
          expect(mutated_approval_rule.groups).to match_array([group])
        end
      end

      context 'with remove_hidden_groups' do
        let(:private_accessible_group) { create(:group, :private) }
        let(:private_inaccessible_group) { create(:group, :private) }
        let(:group_ids) { [private_accessible_group.id] }

        before do
          rule.groups = [private_accessible_group, private_inaccessible_group]
          private_accessible_group.add_guest user
        end

        context 'when is not specified' do
          it 'preserve inaccessible groups' do
            expect(mutated_approval_rule.groups).to match_array([private_accessible_group, private_inaccessible_group])
          end
        end

        context 'when is set to true' do
          let(:remove_hidden_groups) { true }

          it 'removes inaccessible groups' do
            expect(mutated_approval_rule.groups).to match_array([private_accessible_group])
          end
        end
      end
    end

    context 'when the user cannot update the approval_rules' do
      before do
        merge_request.project.add_guest(user)
      end

      it 'receives unauthorized status' do
        expect { subject }.to raise_error(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
