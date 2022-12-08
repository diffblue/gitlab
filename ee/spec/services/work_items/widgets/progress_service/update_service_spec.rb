# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::ProgressService::UpdateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, :objective, project: project, author: user) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Progress) } }

  def work_item_progress
    work_item.reload.progress&.progress
  end

  describe '#before_update_in_transaction' do
    subject { described_class.new(widget: widget, current_user: user).before_update_in_transaction(params: params) }

    shared_examples 'work item and progress is unchanged' do
      it 'does not change work item progress value' do
        expect { subject }
          .to not_change { work_item_progress }
          .and not_change { work_item.updated_at }
      end
    end

    shared_examples 'progress is updated' do |new_value|
      it 'updates work item progress value' do
        expect { subject }
          .to change { work_item_progress }.to(new_value)
      end
    end

    shared_examples 'raises a WidgetError' do
      it { expect { subject }.to raise_error(described_class::WidgetError, message) }
    end

    context 'when progress feature is licensed' do
      before do
        stub_licensed_features(okrs: true)
      end

      context 'when user cannot update work item' do
        let(:params) { { progress: 10 } }

        before do
          project.add_guest(user)
        end

        it_behaves_like 'work item and progress is unchanged'
      end

      context 'when user can update work item' do
        before do
          project.add_reporter(user)
        end

        context 'when progress param is present' do
          context 'when progress param is valid' do
            let(:params) { { progress: 20 } }

            it_behaves_like 'progress is updated', 20
          end

          context 'when progress param is invalid' do
            context 'if progress is greater than 100' do
              let(:params) { { progress: 101 } }

              it_behaves_like 'raises a WidgetError' do
                let(:message) { 'Progress must be less than or equal to 100' }
              end
            end

            context 'if progress is less than 0' do
              let(:params) { { progress: -1 } }

              it_behaves_like 'raises a WidgetError' do
                let(:message) { 'Progress must be greater than or equal to 0' }
              end
            end
          end
        end

        context 'when progress param is not present' do
          let(:params) { {} }

          it_behaves_like 'work item and progress is unchanged'
        end

        context 'when progress param is nil' do
          let(:params) { { progress: nil } }

          it_behaves_like 'raises a WidgetError' do
            let(:message) { 'Progress is not a number' }
          end
        end
      end
    end
  end
end
