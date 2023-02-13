# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItem do
  describe '#supported_quick_action_commands' do
    subject { work_item.supported_quick_action_commands }

    before do
      stub_licensed_features(issuable_health_status: true, issue_weights: true)
    end

    context 'when work item supports the health status widget' do
      let(:work_item) { build(:work_item, :objective) }

      it 'returns health status related quick action commands' do
        is_expected.to include(:health_status, :clear_health_status)
      end
    end

    context 'when work item does not the health status widget' do
      let(:work_item) { build(:work_item, :task) }

      it 'omits assignee related quick action commands' do
        is_expected.not_to include(:health_status, :clear_health_status)
      end
    end

    context 'when work item supports the weight widget' do
      let(:work_item) { build(:work_item, :task) }

      it 'returns labels related quick action commands' do
        is_expected.to include(:weight, :clear_weight)
      end
    end

    context 'when work item does not support the weight widget' do
      let(:work_item) { build(:work_item, :objective) }

      it 'omits labels related quick action commands' do
        is_expected.not_to include(:weight, :clear_weight)
      end
    end
  end

  describe '#widgets' do
    subject { build(:work_item).widgets }

    context 'for weight widget' do
      context 'when issuable weights is licensed' do
        before do
          stub_licensed_features(issue_weights: true)
        end

        it 'returns an instance of the weight widget' do
          is_expected.to include(instance_of(WorkItems::Widgets::Weight))
        end
      end

      context 'when issuable weights is unlicensed' do
        before do
          stub_licensed_features(issue_weights: false)
        end

        it 'omits an instance of the weight widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::Weight))
        end
      end
    end

    context 'for status widget', feature_category: :requirements_management do
      subject { build(:work_item, :requirement).widgets }

      context 'when requirements is licensed' do
        before do
          stub_licensed_features(requirements: true)
        end

        it 'returns an instance of the status widget' do
          is_expected.to include(instance_of(WorkItems::Widgets::Status))
        end
      end

      context 'when status is unlicensed' do
        before do
          stub_licensed_features(requirements: false)
        end

        it 'omits an instance of the status widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::Status))
        end
      end
    end

    context 'for iteration widget' do
      context 'when iterations is licensed' do
        subject { build(:work_item, *work_item_type).widgets }

        before do
          stub_licensed_features(iterations: true)
        end

        context 'when work item supports iteration' do
          where(:work_item_type) { [:task, :issue] }

          with_them do
            it 'returns an instance of the iteration widget' do
              is_expected.to include(instance_of(WorkItems::Widgets::Iteration))
            end
          end
        end

        context 'when work item does not support iteration' do
          let(:work_item_type) { :requirement }

          it 'omits an instance of the iteration widget' do
            is_expected.not_to include(instance_of(WorkItems::Widgets::Iteration))
          end
        end
      end

      context 'when iterations is unlicensed' do
        before do
          stub_licensed_features(iterations: false)
        end

        it 'omits an instance of the iteration widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::Iteration))
        end
      end
    end

    context 'for progress widget' do
      context 'when okrs is licensed' do
        subject { build(:work_item, *work_item_type).widgets }

        before do
          stub_licensed_features(okrs: true)
        end

        context 'when work item supports progress' do
          let(:work_item_type) { [:objective] }

          it 'returns an instance of the progress widget' do
            is_expected.to include(instance_of(WorkItems::Widgets::Progress))
          end
        end

        context 'when work item does not support progress' do
          let(:work_item_type) { :requirement }

          it 'omits an instance of the progress widget' do
            is_expected.not_to include(instance_of(WorkItems::Widgets::Progress))
          end
        end
      end

      context 'when okrs is unlicensed' do
        before do
          stub_licensed_features(okrs: false)
        end

        it 'omits an instance of the progress widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::Progress))
        end
      end
    end

    context 'for health status widget' do
      context 'when issuable_health_status is licensed' do
        subject { build(:work_item, *work_item_type).widgets }

        before do
          stub_licensed_features(issuable_health_status: true)
        end

        context 'when work item supports health_status' do
          where(:work_item_type) { [:issue, :objective, :key_result] }

          with_them do
            it 'returns an instance of the health status widget' do
              is_expected.to include(instance_of(WorkItems::Widgets::HealthStatus))
            end
          end
        end

        context 'when work item does not support health status' do
          where(:work_item_type) { [:test_case, :requirement] }

          with_them do
            it 'omits an instance of the health status widget' do
              is_expected.not_to include(instance_of(WorkItems::Widgets::HealthStatus))
            end
          end
        end
      end

      context 'when issuable_health_status is unlicensed' do
        before do
          stub_licensed_features(issuable_health_status: false)
        end

        it 'omits an instance of the health status widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::HealthStatus))
        end
      end
    end

    context 'for legacy requirement widget', feature_category: :requirements_management do
      let(:work_item_type) { [:requirement] }

      context 'when requirements feature is licensed' do
        subject { build(:work_item, *work_item_type).widgets }

        before do
          stub_licensed_features(requirements: true)
        end

        context 'when work item supports legacy requirement' do
          it 'returns an instance of the legacy requirement widget' do
            is_expected.to include(instance_of(WorkItems::Widgets::RequirementLegacy))
          end
        end

        context 'when work item does not support legacy requirement' do
          where(:work_item_type) { [:test_case, :issue, :objective, :key_result] }

          with_them do
            it 'omits an instance of the legacy requirement widget' do
              is_expected.not_to include(instance_of(WorkItems::Widgets::RequirementLegacy))
            end
          end
        end
      end

      context 'when requirements feature is unlicensed' do
        before do
          stub_licensed_features(requirements: false)
        end

        it 'omits an instance of the legacy requirement widget' do
          is_expected.not_to include(instance_of(WorkItems::Widgets::RequirementLegacy))
        end
      end
    end
  end

  describe '#average_progress_of_children' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_reload(:parent_work_item) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child_work_item1) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child_work_item2) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child_work_item3) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:child1_progress) { create(:progress, work_item: child_work_item1, progress: 20) }
    let_it_be_with_reload(:child2_progress) { create(:progress, work_item: child_work_item2, progress: 30) }
    let_it_be_with_reload(:child3_progress) { create(:progress, work_item: child_work_item3, progress: 30) }

    context 'when workitem has zero children' do
      it 'returns 0 as average' do
        expect(parent_work_item.average_progress_of_children).to eq(0)
      end
    end

    context 'when work item has children' do
      before_all do
        create(:parent_link, work_item: child_work_item1, work_item_parent: parent_work_item)
        create(:parent_link, work_item: child_work_item2, work_item_parent: parent_work_item)
      end

      it 'returns the average of children progress' do
        expect(parent_work_item.average_progress_of_children).to eq(25)
      end

      it 'rounds the average to lower number' do
        create(:parent_link, work_item: child_work_item3, work_item_parent: parent_work_item)

        expect(parent_work_item.average_progress_of_children).to eq(26)
      end
    end
  end

  it_behaves_like 'a collection filtered by test reports state', feature_category: :requirements_management do
    let_it_be(:requirement1) { create(:work_item, :requirement) }
    let_it_be(:requirement2) { create(:work_item, :requirement) }
    let_it_be(:requirement3) { create(:work_item, :requirement) }
    let_it_be(:requirement4) { create(:work_item, :requirement) }

    before do
      create(:test_report, requirement_issue: requirement1, state: :passed)
      create(:test_report, requirement_issue: requirement1, state: :failed)
      create(:test_report, requirement_issue: requirement2, state: :failed)
      create(:test_report, requirement_issue: requirement2, state: :passed)
      create(:test_report, requirement_issue: requirement3, state: :passed)
    end
  end
end
