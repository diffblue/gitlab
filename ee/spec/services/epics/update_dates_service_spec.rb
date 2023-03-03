# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::UpdateDatesService, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group, :internal) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  describe '#execute' do
    context 'fixed date is set' do
      let(:epic) { create(:epic, :use_fixed_dates, start_date: nil, end_date: nil, group: group) }

      it 'updates to fixed date' do
        described_class.new([epic]).execute

        epic.reload
        expect(epic.start_date).to eq(epic.start_date_fixed)
        expect(epic.due_date).to eq(epic.due_date_fixed)
      end
    end

    context 'fixed date is not set' do
      subject { create(:epic, start_date: nil, end_date: nil, group: group) }

      let(:milestone1) do
        create(
          :milestone,
          start_date: Date.new(2000, 1, 1),
          due_date: Date.new(2000, 1, 10),
          group: group
        )
      end

      let(:milestone2) do
        create(
          :milestone,
          start_date: Date.new(2000, 1, 3),
          due_date: Date.new(2000, 1, 20),
          group: group
        )
      end

      context 'multiple milestones' do
        before do
          issue1 = create(:issue, project: project, milestone: milestone1)
          issue2 = create(:issue, project: project, milestone: milestone2)

          create(:epic_issue, epic: epic, issue: issue1)
          create(:epic_issue, epic: epic, issue: issue2)
        end

        context 'complete start and due dates' do
          it 'updates to milestone dates' do
            described_class.new([epic]).execute

            epic.reload
            expect(epic.start_date).to eq(milestone1.start_date)
            expect(epic.due_date).to eq(milestone2.due_date)
          end
        end

        context 'without due date' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: Date.new(2000, 1, 1),
              due_date: nil,
              group: group
            )
          end

          let(:milestone2) do
            create(
              :milestone,
              start_date: Date.new(2000, 1, 3),
              due_date: nil,
              group: group
            )
          end

          it 'updates to milestone dates' do
            described_class.new([epic]).execute

            epic.reload
            expect(epic.start_date).to eq(milestone1.start_date)
            expect(epic.due_date).to eq(nil)
          end
        end

        context 'without any dates' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: nil,
              due_date: nil,
              group: group
            )
          end

          let(:milestone2) do
            create(
              :milestone,
              start_date: nil,
              due_date: nil,
              group: group
            )
          end

          it 'updates to milestone dates' do
            described_class.new([epic]).execute

            epic.reload
            expect(epic.start_date).to eq(nil)
            expect(epic.due_date).to eq(nil)
          end
        end
      end

      context 'without milestone' do
        before do
          create(:epic_issue, epic: epic, issue: issue)
        end

        it 'updates to milestone dates' do
          described_class.new([epic]).execute

          epic.reload
          expect(epic.start_date).to eq(nil)
          expect(epic.start_date_sourcing_milestone_id).to eq(nil)
          expect(epic.due_date).to eq(nil)
          expect(epic.due_date_sourcing_milestone_id).to eq(nil)
        end
      end

      context 'single milestone' do
        before do
          create(:epic_issue, epic: epic, issue: issue)
          issue.update!(milestone: milestone1, project: project)
        end

        context 'complete start and due dates' do
          it 'updates to milestone dates' do
            described_class.new([epic]).execute

            epic.reload
            expect(epic.start_date).to eq(milestone1.start_date)
            expect(epic.due_date).to eq(milestone1.due_date)
          end
        end

        context 'without due date' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: Date.new(2000, 1, 1),
              due_date: nil,
              group: group
            )
          end

          it 'updates to milestone dates' do
            described_class.new([epic]).execute

            epic.reload
            expect(epic.start_date).to eq(milestone1.start_date)
            expect(epic.due_date).to eq(nil)
          end
        end

        context 'without any dates' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: nil,
              due_date: nil,
              group: group
            )
          end

          it 'updates to milestone dates' do
            described_class.new([epic]).execute

            epic.reload
            expect(epic.start_date).to eq(nil)
            expect(epic.due_date).to eq(nil)
          end
        end
      end
    end

    describe '#when updating multiple epics' do
      let(:milestone) { create(:milestone, start_date: Date.new(2000, 1, 1), due_date: Date.new(2000, 1, 10), group: group) }

      def link_epic_to_milestone(epic, milestone)
        create(:issue, epic: epic, milestone: milestone, project: project)
      end

      it 'updates in bulk' do
        milestone1 = create(:milestone, start_date: Date.new(2000, 1, 1), due_date: Date.new(2000, 1, 10), group: group)
        milestone2 = create(:milestone, due_date: Date.new(2000, 1, 30), group: group)

        epics = [
          create(:epic, group: group),
          create(:epic, group: group),
          create(:epic, :use_fixed_dates, group: group)
        ]
        old_attributes = epics.map(&:attributes)

        link_epic_to_milestone(epics[0], milestone1)
        link_epic_to_milestone(epics[0], milestone2)
        link_epic_to_milestone(epics[1], milestone2)
        link_epic_to_milestone(epics[2], milestone1)
        link_epic_to_milestone(epics[2], milestone2)

        described_class.new(epics).execute

        epics.each(&:reload)

        expect(epics[0].start_date).to eq(milestone1.start_date)
        expect(epics[0].start_date_sourcing_milestone).to eq(milestone1)
        expect(epics[0].due_date).to eq(milestone2.due_date)
        expect(epics[0].due_date_sourcing_milestone).to eq(milestone2)

        expect(epics[1].start_date).to eq(nil)
        expect(epics[1].start_date_sourcing_milestone).to eq(nil)
        expect(epics[1].due_date).to eq(milestone2.due_date)
        expect(epics[1].due_date_sourcing_milestone).to eq(milestone2)

        expect(epics[2].start_date).to eq(old_attributes[2]['start_date'])
        expect(epics[2].start_date).to eq(epics[2].start_date_fixed)
        expect(epics[2].start_date_sourcing_milestone).to eq(nil)
        expect(epics[2].due_date).to eq(old_attributes[2]['end_date'])
        expect(epics[2].due_date).to eq(epics[2].due_date_fixed)
        expect(epics[2].due_date_sourcing_milestone).to eq(nil)
      end

      context 'query count check' do
        let!(:epics) { create_list(:epic, 2, group: group) }

        def setup_control_group
          link_epic_to_milestone(epics[0], milestone)
          link_epic_to_milestone(epics[1], milestone)

          ActiveRecord::QueryRecorder.new do
            described_class.new(epics).execute
          end.count
        end

        it 'does not increase query count when adding epics without milestones' do
          control_count = setup_control_group

          epics << create(:epic)
          epics << create(:epic)

          expect do
            described_class.new(epics).execute
          end.not_to exceed_query_limit(control_count)
        end

        it 'does not increase query count when adding epics belongs to same milestones' do
          control_count = setup_control_group

          epics << create(:epic)
          epics << create(:epic)

          link_epic_to_milestone(epics[1], milestone)
          link_epic_to_milestone(epics[2], milestone)

          expect do
            described_class.new(epics).execute
          end.not_to exceed_query_limit(control_count)
        end
      end
    end

    context "when epic dates are inherited" do
      let(:epic) { create(:epic, group: group) }

      context 'when epic has no issues' do
        it "epic dates are nil" do
          described_class.new([epic]).execute

          epic.reload
          expect(epic.start_date).to be_nil
          expect(epic.end_date).to be_nil
          expect(epic.start_date_sourcing_milestone).to be_nil
          expect(epic.due_date_sourcing_milestone).to be_nil
        end
      end

      context 'when epic has issues assigned to milestones' do
        let(:milestone1) { create(:milestone, group: group, start_date: Date.new(2000, 1, 1), due_date: Date.new(2001, 1, 10)) }
        let(:milestone2) { create(:milestone, group: group, start_date: Date.new(2001, 1, 1), due_date: Date.new(2002, 1, 10)) }
        let!(:issue1) { create(:issue, epic: epic, project: project, milestone: milestone1) }
        let!(:issue2) { create(:issue, epic: epic, project: project, milestone: milestone2) }

        it "returns inherited milestone dates" do
          described_class.new([epic]).execute
          epic.reload

          expect(epic.start_date).to eq(milestone1.start_date)
          expect(epic.end_date).to eq(milestone2.due_date)
          expect(epic.start_date_sourcing_milestone).to eq(milestone1)
          expect(epic.due_date_sourcing_milestone).to eq(milestone2)
          expect(epic.start_date_sourcing_epic).to be_nil
          expect(epic.due_date_sourcing_epic).to be_nil
        end

        context "when epic has child epics" do
          let!(:child_epic) { create(:epic, group: group, parent: epic, start_date: Date.new(1998, 1, 1), end_date: Date.new(1999, 1, 1)) }

          it "returns inherited dates from child epics and milestones" do
            expect(Epics::UpdateEpicsDatesWorker).not_to receive(:perform_async)
            described_class.new([epic]).execute
            epic.reload

            expect(epic.start_date).to eq(child_epic.start_date)
            expect(epic.end_date).to eq(milestone2.due_date)
            expect(epic.start_date_sourcing_milestone).to be_nil
            expect(epic.due_date_sourcing_milestone).to eq(milestone2)
            expect(epic.start_date_sourcing_epic).to eq(child_epic)
            expect(epic.due_date_sourcing_epic).to be_nil
          end

          context "when epic dates are propagated upwards", :sidekiq_inline do
            let(:top_level_parent_epic) { create(:epic, group: group) }
            let(:parent_epic) { create(:epic, group: group, parent: top_level_parent_epic) }

            before do
              epic.update!(parent: parent_epic)
            end

            it "propagates date changes to parent epics" do
              expect(Epics::UpdateEpicsDatesWorker).to receive(:perform_async)
                .with([epic.parent_id])
                .and_call_original

              expect(Epics::UpdateEpicsDatesWorker).to receive(:perform_async)
                .with([parent_epic.parent_id])
                .and_call_original

              described_class.new([epic]).execute

              epic.reload
              parent_epic.reload
              top_level_parent_epic.reload

              expect(parent_epic.start_date).to eq(epic.start_date)
              expect(parent_epic.end_date).to eq(epic.due_date)
              expect(parent_epic.start_date_sourcing_milestone).to be_nil
              expect(parent_epic.due_date_sourcing_milestone).to be_nil
              expect(parent_epic.start_date_sourcing_epic).to eq(epic)
              expect(parent_epic.due_date_sourcing_epic).to eq(epic)

              expect(top_level_parent_epic.start_date).to eq(parent_epic.start_date)
              expect(top_level_parent_epic.end_date).to eq(parent_epic.due_date)
              expect(top_level_parent_epic.start_date_sourcing_milestone).to be_nil
              expect(top_level_parent_epic.due_date_sourcing_milestone).to be_nil
              expect(top_level_parent_epic.start_date_sourcing_epic).to eq(parent_epic)
              expect(top_level_parent_epic.due_date_sourcing_epic).to eq(parent_epic)
            end
          end
        end
      end
    end
  end
end
