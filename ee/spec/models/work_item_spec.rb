# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItem do
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

    context 'for status widget' do
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
  end

  it_behaves_like 'a collection filtered by test reports state' do
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
