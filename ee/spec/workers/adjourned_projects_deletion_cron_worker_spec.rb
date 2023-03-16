# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdjournedProjectsDeletionCronWorker, feature_category: :compliance_management do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let_it_be(:user) { create(:user) }
    let_it_be(:marked_for_deletion_at) { 14.days.ago }

    let!(:project_marked_for_deletion) { create(:project, marked_for_deletion_at: marked_for_deletion_at, deleting_user: user) }

    before do
      create(:project)
      create(:project, marked_for_deletion_at: 3.days.ago)
    end

    it 'only schedules to delete projects marked for deletion before number of days from settings' do
      expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(0, project_marked_for_deletion.id)

      worker.perform
    end

    context 'when two projects are scheduled for deletion' do
      let_it_be(:project_marked_for_deletion_two) { create(:project, marked_for_deletion_at: marked_for_deletion_at, deleting_user: user) }

      it 'schedules the second job 10 seconds after the first' do
        expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(10, project_marked_for_deletion.id)
        expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(0, project_marked_for_deletion_two.id)

        worker.perform
      end
    end

    context 'marked for deletion exectly before number of days from settings' do
      let(:marked_for_deletion_at) { 7.days.ago }

      it 'schedules to delete project' do
        expect(AdjournedProjectDeletionWorker).to receive(:perform_in).with(0, project_marked_for_deletion.id)

        worker.perform
      end
    end

    context 'when settings are set to not-default number of days' do
      before do
        create(:project, marked_for_deletion_at: 5.days.ago)
        allow(Gitlab::CurrentSettings).to receive(:deletion_adjourned_period).and_return(4)
      end

      it 'only schedules to delete projects marked for deletion before number of days from settings' do
        expect(AdjournedProjectDeletionWorker).to receive(:perform_in).twice

        worker.perform
      end
    end
  end
end
