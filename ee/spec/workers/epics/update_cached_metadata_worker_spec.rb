# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::UpdateCachedMetadataWorker, feature_category: :portfolio_management do
  include ExclusiveLeaseHelpers

  describe '#perform', :sidekiq_inline do
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, group: group) }
    let_it_be_with_reload(:parent_epic) { create(:epic, group: group) }
    let_it_be_with_reload(:epic) { create(:epic, parent: parent_epic, group: group) }
    let_it_be_with_reload(:other_epic) { create(:epic) }
    let_it_be(:issue1) { create(:issue, weight: 20, project: project) }
    let_it_be(:issue2) { create(:issue, weight: 30, project: project) }
    let_it_be(:issue3) { create(:issue, :closed, weight: 10, project: project) }
    let_it_be(:epic_issue1) { create(:epic_issue, epic: epic, issue: issue1) }
    let_it_be(:epic_issue2) { create(:epic_issue, epic: parent_epic, issue: issue2) }
    let_it_be(:epic_issue3) { create(:epic_issue, epic: epic, issue: issue3) }

    let(:epic_ids) { [epic.id] }
    let(:worker) { described_class.new }

    subject(:perform) { worker.perform(epic_ids) }

    shared_examples_for 'successful metadata update' do
      it 'updates epic issue cached metadata and changes are propagated to ancestors', :aggregate_failures do
        expect(epic.total_opened_issue_weight).to eq(0)
        expect(epic.total_closed_issue_weight).to eq(0)
        expect(epic.total_opened_issue_count).to eq(0)
        expect(epic.total_closed_issue_count).to eq(0)
        expect(parent_epic.total_opened_issue_weight).to eq(0)
        expect(parent_epic.total_closed_issue_weight).to eq(0)
        expect(parent_epic.total_opened_issue_count).to eq(0)
        expect(parent_epic.total_closed_issue_count).to eq(0)

        subject

        epic.reload
        parent_epic.reload
        expect(epic.total_opened_issue_weight).to eq(20)
        expect(epic.total_closed_issue_weight).to eq(10)
        expect(epic.total_opened_issue_count).to eq(1)
        expect(epic.total_closed_issue_count).to eq(1)
        expect(parent_epic.total_opened_issue_weight).to eq(50)
        expect(parent_epic.total_closed_issue_weight).to eq(10)
        expect(parent_epic.total_opened_issue_count).to eq(2)
        expect(parent_epic.total_closed_issue_count).to eq(1)
      end
    end

    it_behaves_like 'successful metadata update'

    it 'logs extra params' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:changed, true)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:epic_id, epic.id)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:epic_iid, epic.iid)
      expect(worker).to receive(:log_extra_metadata_on_done)
        .with(:total_opened_issue_weight, 20)
      expect(worker).to receive(:log_extra_metadata_on_done)
        .with(:total_closed_issue_weight, 10)
      expect(worker).to receive(:log_extra_metadata_on_done)
        .with(:total_opened_issue_count, 1)
      expect(worker).to receive(:log_extra_metadata_on_done)
        .with(:total_closed_issue_count, 1)

      perform
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { epic_ids }

      it_behaves_like 'successful metadata update'
    end

    context 'when epic id not found' do
      let(:epic_ids) { [non_existing_record_id] }

      it 'does nothing' do
        expect(worker).not_to receive(:update_epic)

        perform
      end
    end

    context 'when multiple epic ids are passed' do
      let(:epic_ids) { [epic.id, other_epic.id] }

      it 'updates epic issue cached metadata for each epic' do
        expect(worker).to receive(:update_epic).with(epic)
        expect(worker).to receive(:update_epic).with(other_epic)

        perform
      end

      it 'obtains exclusive lock for each epic' do
        uuid = 'uuid'

        expect_to_obtain_exclusive_lease(
          "#{described_class.name.underscore}-#{epic.id}",
          uuid,
          timeout: described_class::LEASE_TIMEOUT
        )
        expect_to_obtain_exclusive_lease(
          "#{described_class.name.underscore}-#{parent_epic.id}",
          uuid,
          timeout: described_class::LEASE_TIMEOUT
        )
        expect_to_obtain_exclusive_lease(
          "#{described_class.name.underscore}-#{other_epic.id}",
          uuid,
          timeout: described_class::LEASE_TIMEOUT
        )
        expect_to_cancel_exclusive_lease("#{described_class.name.underscore}-#{epic.id}", uuid)
        expect_to_cancel_exclusive_lease("#{described_class.name.underscore}-#{parent_epic.id}", uuid)
        expect_to_cancel_exclusive_lease("#{described_class.name.underscore}-#{other_epic.id}", uuid)

        perform
      end

      context 'when some epics are locked' do
        before do
          stub_exclusive_lease_taken(
            "#{described_class.name.underscore}-#{epic.id}",
            timeout: described_class::LEASE_TIMEOUT
          )
        end

        it 're-schedules the job for locked epics' do
          expect(worker).to receive(:update_epic).with(other_epic)
          expect(worker).not_to receive(:update_epic).with(epic)
          expect(described_class).to receive(:perform_in).with(described_class::LEASE_TIMEOUT, [epic.id])

          perform
        end
      end

      context "when epic's group was deleted during cache update" do
        before do
          allow(worker).to receive(:update_epic).with(other_epic).and_wrap_original do |method, *args|
            other_epic.group.destroy!

            method.call(*args)
          end
        end

        it 'skips invalid epic and logs an error' do
          expect(worker).to receive(:update_epic).with(epic).and_call_original
          expect(Sidekiq.logger).to receive(:error).with(
            hash_including(
              'epic_id' => other_epic.id,
              'message' => "skipping cache update, validation failed: Group can't be blank"
            )
          ).and_call_original

          perform
        end
      end
    end
  end
end
