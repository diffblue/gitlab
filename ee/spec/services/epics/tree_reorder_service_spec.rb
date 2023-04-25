# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::TreeReorderService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:ancestor) { create(:group) }
    let_it_be(:group) { create(:group, parent: ancestor) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue1) { create(:issue, project: project) }
    let_it_be(:issue2) { create(:issue, project: project) }

    let(:epic) { create(:epic, group: group) }
    let(:epic1) { create(:epic, group: group, parent: epic, relative_position: 10) }
    let(:epic2) { create(:epic, group: group, parent: epic, relative_position: 20) }
    let(:epic_issue1) { create(:epic_issue, epic: epic, issue: issue1, relative_position: 30) }
    let(:epic_issue2) { create(:epic_issue, epic: epic, issue: issue2, relative_position: 40) }

    let(:relative_position) { 'after' }
    let!(:tree_object_1) { epic1 }
    let!(:tree_object_2) { epic2 }
    let(:adjacent_reference_id) { GitlabSchema.id_from_object(tree_object_1) }
    let(:moving_object_id) { GitlabSchema.id_from_object(tree_object_2) }
    let(:new_parent_id) { nil }
    let(:params) do
      {
        base_epic_id: GitlabSchema.id_from_object(epic),
        adjacent_reference_id: adjacent_reference_id,
        relative_position: relative_position,
        new_parent_id: new_parent_id
      }
    end

    subject { described_class.new(user, moving_object_id, params).execute }

    shared_examples 'error for the tree update' do |expected_error|
      it 'does not change anything', :aggregate_failures do
        expect { subject }.not_to change { tree_object_1.reload.relative_position }
        expect { subject }.not_to change { tree_object_2.reload.relative_position }
        expect { subject }.not_to change { tree_object_2.reload.parent }

        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq(expected_error)
      end
    end

    context 'when epics feature is not enabled' do
      it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when user does not have permissions to admin the base epic' do
        it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
      end

      context 'when user does have admin_issue_relation permission for the base epic' do
        before do
          group.add_guest(user)
        end

        context 'when moving EpicIssue' do
          let!(:tree_object_1) { epic_issue1 }
          let!(:tree_object_2) { epic_issue2 }

          context 'when relative_position is not valid' do
            let(:relative_position) { 'whatever' }

            it_behaves_like 'error for the tree update', 'Relative position is not valid.'
          end

          context 'when object being moved is not the same type as the switched object' do
            let!(:tree_object_3) { epic1 }
            let!(:tree_object_4) { epic2 }
            let(:adjacent_reference_id) { GitlabSchema.id_from_object(epic2) }

            it 'reorders the objects' do
              subject

              expect(epic2.reload.relative_position).to be > tree_object_2.reload.relative_position
            end
          end

          context 'when no object to switch is provided' do
            let(:adjacent_reference_id) { nil }
            let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

            before do
              tree_object_2.update!(epic: epic1)
            end

            it 'updates the parent' do
              expect { subject }.to change { tree_object_2.reload.epic }.from(epic1).to(epic)
            end

            it 'creates system notes', :sidekiq_inline do
              expect { subject }.to change { Note.system.count }.by(3)
            end
          end

          context 'when object being moved is from another epic' do
            before do
              other_epic = create(:epic, group: group)
              epic_issue2.update!(epic: other_epic)
            end

            context 'when the new_parent_id has not been provided' do
              it_behaves_like 'error for the tree update', "The sibling object's parent must match the current parent epic."
            end

            context 'when the new_parent_id does not match the parent of the relative positioning object' do
              let(:unrelated_epic) { create(:epic, group: group) }
              let(:new_parent_id) { GitlabSchema.id_from_object(unrelated_epic) }

              it_behaves_like 'error for the tree update', "The sibling object's parent must match the new parent epic."
            end

            context 'when the new_parent_id matches the parent id of the relative positioning object' do
              let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

              it 'reorders the objects' do
                subject

                expect(epic2.reload.relative_position).to be > tree_object_2.reload.relative_position
              end
            end
          end

          context 'when object being moved is not supported type' do
            let(:moving_object_id) { GitlabSchema.id_from_object(issue1) }

            it_behaves_like 'error for the tree update', 'Only epics and epic_issues are supported.'
          end

          context 'when adjacent object is not supported type' do
            let(:adjacent_reference_id) { GitlabSchema.id_from_object(issue2) }

            it_behaves_like 'error for the tree update', 'Only epics and epic_issues are supported.'
          end

          context 'when user does not have permissions to move issue' do
            let_it_be(:private_project) { create(:project, :private) }
            let_it_be(:private_issue1) { create(:issue, project: private_project) }
            let_it_be(:private_issue2) { create(:issue, project: private_project) }
            let!(:private_epic_issue1) { create(:epic_issue, epic: epic, issue: private_issue1, relative_position: 50) }
            let!(:private_epic_issue2) { create(:epic_issue, epic: epic, issue: private_issue2, relative_position: 60) }

            let!(:tree_object_1) { private_epic_issue1 }
            let!(:tree_object_2) { private_epic_issue2 }

            it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
          end

          context 'when user does not have permissions to admin the previous parent' do
            let(:other_epic) { create(:epic, group: ancestor) }
            let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

            before do
              epic_issue2.update!(parent: other_epic)
            end

            it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
          end

          context 'when user does not have permissions to admin the new parent' do
            let(:other_epic) { create(:epic, group: ancestor) }
            let(:new_parent_id) { GitlabSchema.id_from_object(other_epic) }

            it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
          end

          context 'when the epics of reordered epic-issue links are not subepics of the base epic' do
            let(:another_epic) { create(:epic, group: ancestor) }

            before do
              epic_issue1.update!(epic: another_epic)
              epic_issue2.update!(epic: another_epic)
            end

            context 'when new_parent_id is not provided' do
              it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
            end

            context 'when new_parent_id is provided' do
              let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

              it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
            end
          end

          context 'when moving is successful' do
            it 'updates the links relative positions' do
              subject

              expect(tree_object_1.reload.relative_position).to be > tree_object_2.reload.relative_position
            end

            context 'when a new_parent_id of a valid parent is provided' do
              let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

              before do
                epic_issue2.update!(epic: epic1)
              end

              it 'updates the parent' do
                expect { subject }.to change { tree_object_2.reload.epic }.from(epic1).to(epic)
              end

              it 'updates the links relative positions' do
                subject

                expect(tree_object_1.reload.relative_position).to be > tree_object_2.reload.relative_position
              end

              it 'creates system notes', :sidekiq_inline do
                expect { subject }.to change { Note.system.count }.by(3)
              end
            end
          end
        end

        context 'when moving Epic' do
          let!(:tree_object_1) { epic1 }
          let!(:tree_object_2) { epic2 }

          context 'when subepics feature is disabled' do
            let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

            before do
              stub_licensed_features(epics: true, subepics: false)
            end

            it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
          end

          context 'when subepics feature is enabled' do
            before do
              stub_licensed_features(epics: true, subepics: true)
            end

            context 'when relative_position is not valid' do
              let(:relative_position) { 'whatever' }

              it_behaves_like 'error for the tree update', 'Relative position is not valid.'
            end

            context 'when user does not have permissions to admin the previous parent' do
              let(:other_epic) { create(:epic, group: ancestor) }
              let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

              before do
                epic2.update!(parent: other_epic)
              end

              it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
            end

            context 'when user does not have permissions to admin the previous parent links' do
              let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

              before do
                user.group_members.delete_all
              end

              it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
            end

            context 'when there is some other error with the new parent' do
              shared_examples 'new parent not in an ancestor group' do
                it 'returns success status without errors', :aggregate_failures do
                  expect(subject[:status]).to eq(:success)
                  expect(subject[:message]).to be_nil
                end
              end

              context 'when the new parent is in a new group hierarchy' do
                let_it_be(:other_group) { create(:group) }

                let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

                before do
                  other_group.add_developer(user)
                  epic.update!(group: other_group)
                  epic2.update!(parent: epic1)
                end

                it_behaves_like 'new parent not in an ancestor group'
              end

              context 'when the new parent is in a descendant group' do
                let_it_be(:descendant_group) { create(:group, parent: group ) }

                let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

                before do
                  descendant_group.add_developer(user)
                  epic.update!(group: descendant_group)
                  epic2.update!(parent: epic1)
                end

                it_behaves_like 'new parent not in an ancestor group'
              end
            end

            context 'when user does not have permissions to admin the new parent' do
              let(:other_epic) { create(:epic, group: ancestor) }
              let(:new_parent_id) { GitlabSchema.id_from_object(other_epic) }

              it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
            end

            context 'when the reordered epics are not subepics of the base epic' do
              let(:another_group) { create(:group) }
              let(:another_epic) { create(:epic, group: another_group) }

              before do
                epic1.update!(group: ancestor, parent: another_epic)
                epic2.update!(group: ancestor, parent: another_epic)
              end

              it_behaves_like 'error for the tree update', 'You don\'t have permissions to move the objects.'
            end

            context 'when moving is successful' do
              it 'updates the links relative positions' do
                subject

                expect(tree_object_1.reload.relative_position).to be > tree_object_2.reload.relative_position
              end

              context 'when new parent is current epic' do
                let(:new_parent_id) { GitlabSchema.id_from_object(epic) }

                it 'updates the relative positions' do
                  subject

                  expect(tree_object_1.reload.relative_position).to be > tree_object_2.reload.relative_position
                end

                it 'does not update the parent_id' do
                  expect { subject }.not_to change { tree_object_2.reload.parent }
                end
              end

              context 'when object being moved is from another epic and new_parent_id matches parent of adjacent object' do
                let(:other_epic) { create(:epic, group: group) }
                let(:new_parent_id) { GitlabSchema.id_from_object(epic) }
                let(:epic3) { create(:epic, parent: other_epic, group: group) }
                let(:tree_object_2) { epic3 }

                it 'updates the relative positions' do
                  subject

                  expect(tree_object_1.reload.relative_position).to be > tree_object_2.reload.relative_position
                end

                it 'updates the parent' do
                  expect { subject }.to change { tree_object_2.reload.parent }.from(other_epic).to(epic)
                end

                it 'creates system notes' do
                  expect { subject }.to change { Note.system.count }.by(3)
                end
              end
            end
          end
        end
      end
    end
  end
end
