# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::EpicLinks::UpdateService, feature_category: :portfolio_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:parent_epic) { create(:epic, group: group) }

  let(:child_epic1) { create(:epic, group: group, parent: parent_epic, relative_position: 1) }
  let(:child_epic2) { create(:epic, group: group, parent: parent_epic, relative_position: 2) }
  let(:child_epic3) { create(:epic, group: group, parent: parent_epic, relative_position: 300) }
  let(:child_epic4) { create(:epic, group: group, parent: parent_epic, relative_position: 400) }

  let(:epic_to_move) { child_epic3 }
  let(:params) { {} }

  subject do
    described_class.new(epic_to_move, user, params).execute
  end

  def ordered_epics
    Epic.where(parent_id: parent_epic.id).order('relative_position, id DESC')
  end

  describe '#execute' do
    before do
      group.add_guest(user)
    end

    shared_examples 'updating timestamps' do
      it 'does not update moved epic' do
        updated_at = epic_to_move.updated_at
        subject

        expect(epic_to_move.reload.updated_at.change(usec: 0)).to eq(updated_at.change(usec: 0))
      end

      it 'does not update parent epic' do
        updated_at = parent_epic.updated_at
        subject

        expect(parent_epic.reload.updated_at.change(usec: 0)).to eq(updated_at.change(usec: 0))
      end
    end

    context 'when subepics feature is not available' do
      it 'returns an error' do
        stub_licensed_features(epics: true, subepics: false)

        expect(subject).to eq(message: 'Epic not found for given params', status: :error, http_status: 404)
      end
    end

    context 'when subepics feature is available' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when user has insufficient permissions' do
        before do
          user.group_members.delete_all
        end

        it 'returns an error' do
          expect(subject).to eq(message: 'Epic not found for given params', status: :error, http_status: 404)
        end
      end

      context 'when params are nil' do
        let(:params) { { move_before_id: nil, move_after_id: nil } }

        it 'does not change order of child epics' do
          expect(subject).to include(status: :success)
          expect(ordered_epics).to eq([child_epic1, child_epic2, child_epic3, child_epic4])
        end
      end

      context 'when moving to start' do
        let(:params) { { move_before_id: nil, move_after_id: child_epic1.id } }

        it_behaves_like 'updating timestamps'

        it 'reorders child epics' do
          expect(subject).to include(status: :success)
          expect(ordered_epics).to eq([child_epic3, child_epic1, child_epic2, child_epic4])
        end
      end

      context 'when moving to end' do
        let(:params) { { move_before_id: child_epic4.id, move_after_id: nil } }

        it_behaves_like 'updating timestamps'

        it 'reorders child epics' do
          expect(subject).to include(status: :success)
          expect(ordered_epics).to eq([child_epic1, child_epic2, child_epic4, child_epic3])
        end
      end

      context 'when moving between siblings' do
        let(:params) { { move_before_id: child_epic1.id, move_after_id: child_epic2.id } }

        it_behaves_like 'updating timestamps'

        it 'reorders child epics' do
          expect(subject).to include(status: :success)
          expect(ordered_epics).to eq([child_epic1, child_epic3, child_epic2, child_epic4])
        end
      end

      context 'when params are invalid' do
        let(:other_epic) { create(:epic, group: group) }

        shared_examples 'returns error' do
          it 'does not change order of child epics and returns error' do
            expect(subject).to include(message: 'Epic not found for given params', status: :error, http_status: 404)
            expect(ordered_epics).to eq([child_epic1, child_epic2, child_epic3, child_epic4])
          end
        end

        context 'when move_before_id is not a child of parent epic' do
          let(:params) { { move_before_id: other_epic.id, move_after_id: child_epic2.id } }

          it_behaves_like 'returns error'
        end

        context 'when move_after_id is not a child of parent epic' do
          let(:params) { { move_before_id: child_epic1.id, move_after_id: other_epic.id } }

          it_behaves_like 'returns error'
        end
      end
    end
  end
end
