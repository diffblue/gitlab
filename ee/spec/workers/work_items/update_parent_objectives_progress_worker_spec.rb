# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateParentObjectivesProgressWorker, feature_category: :team_planning do
  describe '#perform', :sidekiq_inline do
    let_it_be(:project) { create(:project) }
    let(:work_item_id) { child_work_item1.id }
    let(:worker) { described_class.new }
    let_it_be_with_reload(:parent_work_item) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child_work_item1) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child_work_item2) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child1_progress) { create(:progress, work_item: child_work_item1, progress: 20) }

    before_all do
      create(:parent_link, work_item: child_work_item1, work_item_parent: parent_work_item)
      create(:parent_link, work_item: child_work_item2, work_item_parent: parent_work_item)
    end

    subject(:perform) { worker.perform(work_item_id) }

    def parent_work_item_progress
      parent_work_item.reload.progress&.progress
    end

    def parent_work_item_current_value
      parent_work_item.reload.progress&.current_value
    end

    shared_examples 'parent progress is not changed' do
      it "doesn't update parent progress" do
        expect { subject }.to not_change { parent_work_item_progress }
      end

      it "doesn't create system note" do
        expect { subject }.to not_change(parent_work_item.notes, :count)
      end
    end

    shared_examples 'parent progress is updated' do |new_value|
      it 'updates parent progress value' do
        expect { subject }
          .to change { parent_work_item_progress }.to(new_value)
          .and change { parent_work_item_current_value }.to(new_value)
      end

      it 'creates notes' do
        expect { subject }.to change { Note.count }.by(1)

        work_item_note = parent_work_item.reload.notes.last

        expect(work_item_note.note).to eq("changed progress to **#{new_value}**")
      end
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { work_item_id }

      it_behaves_like 'parent progress is updated', 10
    end

    context 'when work_item id not found' do
      let(:work_item_id) { non_existing_record_id }

      it 'does nothing' do
        expect(worker).not_to receive(:update_parent_progress)

        perform
      end
    end

    context 'when parent progress is not created' do
      let(:job_args) { work_item_id }

      it_behaves_like 'parent progress is updated', 10
    end

    context 'when parent progress is average of its children' do
      before do
        create(:progress, work_item: parent_work_item, progress: 10)
      end

      let(:job_args) { work_item_id }

      it_behaves_like 'parent progress is not changed'
    end

    context 'when parent progress is not average of its children' do
      before do
        create(:progress, work_item: parent_work_item, progress: 20)
      end

      let(:job_args) { work_item_id }

      it_behaves_like 'parent progress is updated', 10
    end
  end
end
