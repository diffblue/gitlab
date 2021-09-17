# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards do
  let!(:group) { create(:group) }
  let!(:project) { create(:project, group: group) }

  let!(:project_board1) { create(:board, name: 'Project Dev1', project: project) }
  let!(:project_board2) { create(:board, name: 'Project Dev2', project: project, iteration_id: -4) }
  let!(:project_board3) { create(:board, name: 'Project Dev3', project: project, iteration_id: -4) }
  let!(:project_board4) { create(:board, name: 'Project Dev4', project: project, iteration_id: -4) }

  let!(:group_board1) {  create(:board, name: 'Group Dev1', group: group) }
  let!(:group_board2) {  create(:board, name: 'Group Dev2', group: group, iteration_id: -4) }
  let!(:group_board3) {  create(:board, name: 'Group Dev3', group: group, iteration_id: -4) }
  let!(:group_board4) {  create(:board, name: 'Group Dev4', group: group, iteration_id: -4) }

  let(:migration) { described_class.new }

  subject { migration.perform(board_type, direction, start_id, end_id) }

  context 'up' do
    let(:direction) { 'up' }

    shared_examples 'resets iteration_id to nil' do
      it 'resets iteration_id to nil' do
        subject

        expect(boards.map(&:iteration_cadence)).to eq([nil, nil, nil])
        expect(boards.map(&:iteration)).to eq([nil, nil, nil])
      end
    end

    context 'when group does not have cadences' do
      context 'back-fill project boards' do
        let(:board_type) { 'project' }
        let(:start_id) { project_board2.id }
        let(:end_id) { project_board4.id }
        let(:boards) { [project_board2.reload, project_board3.reload, project_board4.reload] }

        it_behaves_like 'resets iteration_id to nil'

        context 'with pagination' do
          before do
            stub_const('::EE::Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards::BATCH_SIZE', 2)
          end

          it 'expect batched updates' do
            expect(migration).to receive(:bulk_update).twice.and_call_original

            subject
          end

          it_behaves_like 'resets iteration_id to nil'
        end
      end

      context 'back-fill group boards' do
        let(:board_type) { 'group' }
        let(:start_id) { group_board2.id }
        let(:end_id) { group_board4.id }
        let(:boards) { [group_board2.reload, group_board3.reload, group_board4.reload] }

        it_behaves_like 'resets iteration_id to nil'

        context 'with pagination' do
          before do
            stub_const('::EE::Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards::BATCH_SIZE', 2)
          end

          it 'expect batched updates' do
            expect(migration).to receive(:bulk_update).twice.and_call_original

            subject
          end

          it_behaves_like 'resets iteration_id to nil'
        end
      end
    end

    context 'when group has cadences' do
      let!(:cadence) { create(:iterations_cadence, group: group) }

      shared_examples 'sets the correct cadence id' do
        it 'sets correct cadence id' do
          subject

          expect(boards.map(&:iteration_cadence_id)).to eq([cadence.id, cadence.id, cadence.id])
          expect(boards.map(&:iteration_id)).to eq([-4, -4, -4])
        end
      end

      context 'when group does not have cadences' do
        context 'back-fill project boards' do
          let(:board_type) { 'project' }
          let(:start_id) { project_board2.id }
          let(:end_id) { project_board4.id }
          let(:boards) { [project_board2.reload, project_board3.reload, project_board4.reload] }

          it_behaves_like 'sets the correct cadence id'

          context 'with pagination' do
            before do
              stub_const('::EE::Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards::BATCH_SIZE', 2)
            end

            it 'expect batched updates' do
              expect(migration).to receive(:bulk_update).twice.and_call_original

              subject
            end

            it_behaves_like 'sets the correct cadence id'
          end
        end

        context 'back-fill group boards' do
          let(:board_type) { 'group' }
          let(:start_id) { group_board2.id }
          let(:end_id) { group_board4.id }
          let(:boards) { [group_board2.reload, group_board3.reload, group_board4.reload] }

          it_behaves_like 'sets the correct cadence id'

          context 'with pagination' do
            before do
              stub_const('::EE::Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards::BATCH_SIZE', 2)
            end

            it 'expect batched updates' do
              expect(migration).to receive(:bulk_update).twice.and_call_original

              subject
            end

            it_behaves_like 'sets the correct cadence id'
          end
        end
      end
    end
  end

  context 'down' do
    let!(:cadence) { create(:iterations_cadence, group: group) }
    let!(:project_board1) { create(:board, name: 'Project Dev1', project: project) }
    let!(:project_board2) { create(:board, name: 'Project Dev2', project: project, iteration_cadence: cadence) }
    let!(:project_board3) { create(:board, name: 'Project Dev3', project: project, iteration_id: -4, iteration_cadence: cadence) }
    let!(:project_board4) { create(:board, name: 'Project Dev4', project: project, iteration_id: -4, iteration_cadence: cadence) }

    let!(:group_board1) {  create(:board, name: 'Group Dev1', group: group) }
    let!(:group_board2) {  create(:board, name: 'Group Dev2', group: group, iteration_cadence: cadence) }
    let!(:group_board3) {  create(:board, name: 'Group Dev3', group: group, iteration_id: -4, iteration_cadence: cadence) }
    let!(:group_board4) {  create(:board, name: 'Group Dev4', group: group, iteration_id: -4, iteration_cadence: cadence) }

    let(:direction) { 'down' }
    let(:board_type) { 'none' }
    let(:start_id) { project_board2.id }
    let(:end_id) { group_board4.id }
    let(:boards) { [project_board2.reload, project_board3.reload, project_board4.reload, group_board2.reload, group_board4.reload, group_board4.reload] }

    it 'resets cadence id to nil' do
      subject

      expect(boards.map(&:iteration_cadence_id)).to eq([nil, nil, nil, nil, nil, nil])
      expect(boards.map(&:iteration_id)).to eq([nil, -4, -4, nil, -4, -4])
    end

    context 'batched' do
      before do
        stub_const('::EE::Gitlab::BackgroundMigration::BackfillIterationCadenceIdForBoards::BATCH_SIZE', 2)
      end

      it 'resets cadence id to nil' do
        subject

        expect(boards.map(&:iteration_cadence_id)).to eq([nil, nil, nil, nil, nil, nil])
        expect(boards.map(&:iteration_id)).to eq([nil, -4, -4, nil, -4, -4])
      end
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
