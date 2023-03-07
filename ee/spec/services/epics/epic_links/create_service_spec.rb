# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::EpicLinks::CreateService, feature_category: :portfolio_management do
  include NestedEpicsHelper

  describe '#execute' do
    let_it_be(:ancestor) { create(:group) }
    let_it_be(:group) { create(:group, parent: ancestor) }
    let_it_be(:user) { create(:user) }
    let_it_be(:other_group) { create(:group) }

    let(:epic) { create(:epic, group: group) }
    let(:epic_to_add) { create(:epic, group: group) }
    let(:expected_error) { 'No matching epic found. Make sure that you are adding a valid epic URL.' }
    let(:expected_code) { 404 }

    let(:valid_reference) { epic_to_add.to_reference(full: true) }

    shared_examples 'system notes created' do
      it 'creates system notes' do
        expect { subject }.to change { Note.system.count }.from(0).to(2)
      end
    end

    shared_examples 'returns success' do
      it 'creates a new relationship and updates epic' do
        expect { subject }.to change { epic.children.count }.by(1)

        expect(epic.reload.children).to include(epic_to_add)
      end

      it 'moves the new child epic to the top and moves the existing ones down' do
        existing_child_epic = create(:epic, group: group, parent: epic, relative_position: 1000)

        subject

        expect(epic_to_add.reload.relative_position).to be < existing_child_epic.reload.relative_position
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(subject.keys).to match_array([:status, :created_references])
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references]).to match_array([epic_to_add])
      end
    end

    shared_examples 'returns an error' do
      it 'returns an error' do
        expect(subject).to eq(message: expected_error, status: :error, http_status: expected_code)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { epic.children.count }
      end
    end

    def add_epic(references)
      params = { issuable_references: references }

      described_class.new(epic, user, params).execute
    end

    context 'when subepics feature is disabled' do
      before do
        stub_licensed_features(epics: true, subepics: false)
      end

      subject { add_epic([valid_reference]) }

      include_examples 'returns an error'
    end

    context 'when subepics feature is enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when an error occurs' do
        context 'when a single epic is given' do
          subject { add_epic([valid_reference]) }

          context 'when a user does not have permissions to add an epic' do
            include_examples 'returns an error'
          end

          context 'when a user has permissions to add an epic' do
            before do
              group.add_guest(user)
            end

            context 'when an epic from another group is given' do
              before do
                epic_to_add.update!(group: other_group)
              end

              context 'when user has no permission to admin_epic_tree_relation' do
                let(:params) { { target_issuable: epic_to_add } }

                subject { described_class.new(epic, user, params).execute }

                before do
                  other_group.add_guest(user)
                  epic_to_add.update!(confidential: true)
                end

                include_examples 'returns an error'
              end

              context 'when subepics feature is not available for child group' do
                let(:expected_code) { 409 }
                let(:expected_error) do
                  "This epic cannot be added. You don't have access to perform this action."
                end

                before do
                  other_group.add_guest(user)
                  stub_licensed_features(epics: true)

                  allow(group).to receive(:licensed_feature_available?).and_return(true)
                  allow(other_group).to receive(:licensed_feature_available?).with(:subepics).and_return(false)
                end

                include_examples 'returns an error'
              end
            end

            context 'when hierarchy is cyclic' do
              context 'when given child epic is the same as given parent' do
                let(:expected_error) { "This epic cannot be added. An epic cannot be added to itself." }
                let(:expected_code) { 409 }

                subject { add_epic([epic.to_reference(full: true)]) }

                include_examples 'returns an error'
              end

              context 'when given child epic is parent of the given parent' do
                let(:expected_error) { "This epic cannot be added. It is already an ancestor of the parent epic." }
                let(:expected_code) { 409 }

                before do
                  epic.update!(parent: epic_to_add)
                end

                include_examples 'returns an error'
              end

              context 'when new child epic is an ancestor of the given parent' do
                let(:expected_error) { "This epic cannot be added. It is already an ancestor of the parent epic." }
                let(:expected_code) { 409 }

                before do
                  # epic_to_add -> epic1 -> epic2 -> epic
                  epic1 = create(:epic, group: group, parent: epic_to_add)
                  epic2 = create(:epic, group: group, parent: epic1)
                  epic.update!(parent: epic2)
                end

                include_examples 'returns an error'
              end
            end

            context 'when adding an epic that is already a child of the parent epic' do
              before do
                epic_to_add.update!(parent: epic)
              end

              let(:expected_error) { "This epic cannot be added. It is already assigned to the parent epic." }
              let(:expected_code) { 409 }

              include_examples 'returns an error'
            end

            context 'when adding to an Epic that is already at maximum depth' do
              before do
                add_parents_to(epic: epic, count: 6)
              end

              let(:expected_code) { 409 }
              let(:expected_error) do
                "This epic cannot be added. One or more epics would exceed the "\
                "maximum depth (#{Epic::MAX_HIERARCHY_DEPTH}) from its most "\
                "distant ancestor."
              end

              include_examples 'returns an error'
            end

            context 'when total depth after adding would exceed depth limit' do
              let(:expected_code) { 409 }
              let(:expected_error) do
                "This epic cannot be added. One or more epics would exceed the "\
                "maximum depth (#{Epic::MAX_HIERARCHY_DEPTH}) from its most "\
                "distant ancestor."
              end

              before do
                add_parents_to(epic: epic, count: 1) # epic is on level 2

                # epic_to_add has 5 children (level 6 including epic_to_add)
                # that would mean level 8 after relating epic_to_add on epic
                add_children_to(epic: epic_to_add, count: 5)
              end

              include_examples 'returns an error'
            end

            context 'when total children count after adding would exceed limit' do
              let(:expected_error) do
                "You cannot add any more epics. This epic already has maximum "\
                "number of child epics."
              end

              let(:expected_code) { 409 }

              before do
                create(:epic, group: group, parent: epic)
                stub_const("EE::Epic::MAX_CHILDREN_COUNT", 1)
              end

              include_examples 'returns an error'
            end
          end
        end

        context 'when multiple epics are given' do
          let_it_be(:another_epic) { create(:epic, group: ancestor) }

          subject do
            add_epic(
              [epic_to_add.to_reference(full: true), another_epic.to_reference(full: true)]
            )
          end

          context 'when a user dos not have permissions to add an epic' do
            include_examples 'returns an error'
          end

          context 'when a user has permissions to add an epic' do
            before do
              group.add_developer(user)
            end

            context 'when adding epics that are already a child of the parent epic' do
              let(:expected_error) { 'Epic(s) already assigned' }
              let(:expected_code) { 409 }

              before do
                epic_to_add.update!(parent: epic)
                another_epic.update!(parent: epic)
              end

              include_examples 'returns an error'
            end

            context 'when total depth after adding would exceed limit' do
              before do
                add_parents_to(epic: epic, count: 1) # epic is on level 2

                # epic_to_add has 5 children (level 6 including epic_to_add)
                # that would mean level 8 after relating epic_to_add on epic
                add_children_to(epic: epic_to_add, count: 5)
              end

              include_examples 'returns an error'
            end

            context 'when an epic from a another group is given' do
              before do
                epic_to_add.update!(group: other_group)
              end

              context 'when user has insufficient permissions' do
                include_examples 'returns an error'
              end

              context 'when subepics feature is not available for child group' do
                before do
                  other_group.add_guest(user)
                  stub_licensed_features(epics: true)

                  allow(group).to receive(:licensed_feature_available?).and_return(true)
                  allow(other_group).to receive(:licensed_feature_available?).with(:subepics).and_return(false)
                end

                include_examples 'returns an error'
              end
            end

            context 'when hierarchy is cyclic' do
              context 'when given child epic is the same as given parent' do
                subject { add_epic([epic.to_reference(full: true), another_epic.to_reference(full: true)]) }

                include_examples 'returns an error'
              end

              context 'when given child epic is parent of the given parent' do
                before do
                  epic.update!(parent: epic_to_add)
                end

                include_examples 'returns an error'
              end
            end

            context 'when the reference list is empty' do
              subject { add_epic([]) }

              include_examples 'returns an error'
            end

            context 'when there are invalid references' do
              let_it_be(:epic) { create(:epic, confidential: true, group: group) }
              let_it_be(:invalid_epic1) { create(:epic, group: group) }
              let_it_be(:valid_epic) { create(:epic, :confidential, group: group) }
              let_it_be(:invalid_epic2) { create(:epic, group: group) }

              subject do
                add_epic([invalid_epic1.to_reference(full: true),
                          valid_epic.to_reference(full: true),
                          invalid_epic2.to_reference(full: true)])
              end

              it 'adds only valid references' do
                subject

                expect(epic.reload.children).to match_array([valid_epic])
              end

              it 'returns error status' do
                expect(subject).to eq(
                  status: :error,
                  http_status: 422,
                  message: "#{invalid_epic1.to_reference} cannot be added: A non-confidential "\
                           "epic cannot be assigned to a confidential parent epic. "\
                           "#{invalid_epic2.to_reference} cannot be added: A non-confidential "\
                           "epic cannot be assigned to a confidential parent epic"
                )
              end
            end
          end
        end
      end

      context 'when everything is ok' do
        let_it_be_with_reload(:another_epic) { create(:epic, group: group) }

        before do
          group.add_guest(user)
        end

        context 'when a correct reference is given' do
          subject { add_epic([valid_reference]) }

          include_examples 'returns success'
          include_examples 'system notes created'
        end

        context 'when an epic from a subgroup is given' do
          let_it_be(:subgroup) { create(:group, parent: group) }

          before do
            epic_to_add.update!(group: subgroup)
          end

          subject { add_epic([valid_reference]) }

          include_examples 'returns success'
          include_examples 'system notes created'
        end

        context 'when an epic from another group is given' do
          before do
            epic_to_add.update!(group: other_group)
            other_group.add_reporter(user)
          end

          subject { add_epic([valid_reference]) }

          include_examples 'returns success'
          include_examples 'system notes created'
        end

        context 'when an epic from ancestor group is given' do
          before do
            ancestor.add_guest(user)
            epic_to_add.update!(group: ancestor)
          end

          subject { add_epic([valid_reference]) }

          include_examples 'returns success'
          include_examples 'system notes created'
        end

        context 'when multiple valid epics are given' do
          subject do
            add_epic(
              [epic_to_add.to_reference(full: true), another_epic.to_reference(full: true)]
            )
          end

          it 'creates new relationships' do
            expect { subject }.to change { epic.children.count }.by(2)

            expect(epic.reload.children).to match_array([epic_to_add, another_epic])
          end

          it 'creates system notes' do
            expect { subject }.to change { Note.system.count }.from(0).to(4)
          end

          it 'returns success status and created links', :aggregate_failures do
            expect(subject.keys).to match_array([:status, :created_references])
            expect(subject[:status]).to eq(:success)
            expect(subject[:created_references]).to match_array([epic_to_add, another_epic])
          end

          it 'avoids un-necessary database queries' do
            control = ActiveRecord::QueryRecorder.new { add_epic([valid_reference]) }

            new_epics = [create(:epic, group: group), create(:epic, group: group)]

            # threshold is 8 because
            # 1. we need to check hierarchy for each child epic (3 queries)
            # 2. we have to update the  record (2 including releasing savepoint)
            # 3. we have to update start and due dates for all updated epics
            # 4. we temporarily increased this from 6 due to
            #    https://gitlab.com/gitlab-org/gitlab/issues/11539
            expect do
              ActiveRecord::QueryRecorder.new { add_epic(new_epics.map { |epic| epic.to_reference(full: true) }) }
            end.not_to exceed_query_limit(control).with_threshold(8)
          end
        end

        context 'when at least one epic is still not assigned to the parent epic' do
          before do
            epic_to_add.update!(parent: epic)
          end

          subject do
            add_epic(
              [epic_to_add.to_reference(full: true), another_epic.to_reference(full: true)]
            )
          end

          it 'creates new relationships' do
            expect { subject }.to change { epic.children.count }.from(1).to(2)

            expect(epic.reload.children).to match_array([epic_to_add, another_epic])
          end

          it 'creates system notes' do
            expect { subject }.to change { Note.system.count }.from(0).to(2)
          end

          it 'returns success status and created links', :aggregate_failures do
            expect(subject.keys).to match_array([:status, :created_references])
            expect(subject[:status]).to eq(:success)
            expect(subject[:created_references]).to match_array([another_epic])
          end
        end

        context 'when adding an Epic that has existing children' do
          context 'when Epic to add has more than 5 children' do
            subject { add_epic([valid_reference]) }

            before do
              create_list(:epic, 8, group: group, parent: epic_to_add)
            end

            include_examples 'returns success'
            include_examples 'system notes created'
          end
        end

        context 'when an epic is already assigned to another epic' do
          before do
            epic_to_add.update!(parent: another_epic)
          end

          subject { add_epic([valid_reference]) }

          it 'creates system notes' do
            expect { subject }.to change { Note.system.count }.from(0).to(3)
          end

          include_examples 'returns success'
        end
      end
    end
  end
end
