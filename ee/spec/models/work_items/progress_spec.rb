# frozen_string_literal: true
require 'spec_helper'

RSpec.describe WorkItems::Progress do
  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
  end

  describe 'validations' do
    it "ensures progress is an integer greater than to equal to 0 and less than or equal to 100" do
      is_expected.to validate_numericality_of(:progress).only_integer.is_greater_than_or_equal_to(0)
                        .is_less_than_or_equal_to(100)
    end

    %w[start_value end_value current_value].each do |attribute|
      it "ensures presence of #{attribute}" do
        is_expected.to validate_presence_of(attribute.to_sym)
      end
    end
  end

  describe '#update_all_parent_objectives_progress' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_reload(:parent_work_item) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child_work_item1) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child_work_item2) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child1_progress) { create(:progress, work_item: child_work_item1, progress: 20) }

    before_all do
      create(:parent_link, work_item: child_work_item1, work_item_parent: parent_work_item)
      create(:parent_link, work_item: child_work_item2, work_item_parent: parent_work_item)
    end

    before do
      stub_licensed_features(okrs: true)
    end

    shared_examples 'parent progress is not changed' do
      it 'does not schedule progress update for parent' do
        expect(::WorkItems::UpdateParentObjectivesProgressWorker).not_to receive(:perform_async)
        subject
      end
    end

    shared_examples 'schedules progress update' do
      it 'schedules progress update for parent' do
        expect(::WorkItems::UpdateParentObjectivesProgressWorker).to receive(:perform_async)
        subject
      end
    end

    context 'when okr_automatic_rollups feature flag is disabled' do
      before do
        stub_feature_flags(okr_automatic_rollups: false)
      end

      subject { child1_progress.update!(progress: 40) }

      it_behaves_like 'parent progress is not changed'
    end

    context 'when okr_automatic_rollups feature flag is enabled' do
      context 'when progress of child doesnt change' do
        subject { child1_progress.save! }

        it_behaves_like 'parent progress is not changed'
      end

      context 'when progress of child changes' do
        context 'when parent progress is not created' do
          subject { child1_progress.update!(progress: 30) }

          it_behaves_like 'schedules progress update'
        end

        context 'when parent progress is created' do
          before do
            create(:progress, work_item: parent_work_item, progress: 10)
          end

          subject { child1_progress.update!(progress: 40) }

          it_behaves_like 'schedules progress update'
        end
      end

      context 'when progress of child 1+ level down changes' do
        let_it_be_with_reload(:child_work_item3) { create(:work_item, :objective, project: project) }
        let_it_be_with_reload(:child_work_item4) { create(:work_item, :objective, project: project) }
        let_it_be_with_reload(:child3_progress) { create(:progress, work_item: child_work_item3, progress: 20) }
        let_it_be_with_reload(:child4_progress) { create(:progress, work_item: child_work_item4, progress: 20) }

        before_all do
          create(:parent_link, work_item: child_work_item3, work_item_parent: child_work_item1)
          create(:parent_link, work_item: child_work_item4, work_item_parent: child_work_item1)
        end
        subject { child3_progress.update!(progress: 80) }

        it_behaves_like 'schedules progress update'
      end
    end
  end
end
