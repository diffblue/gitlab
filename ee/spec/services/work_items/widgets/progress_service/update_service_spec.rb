# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::ProgressService::UpdateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, :objective, project: project, author: user) }
  let_it_be_with_reload(:progress) { create(:progress, work_item: work_item, progress: 5, current_value: 5) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Progress) } }

  def work_item_progress
    work_item.reload.progress&.progress
  end

  def work_item_current_value
    work_item.reload.progress&.current_value
  end

  describe '#before_update_in_transaction' do
    let(:service) { described_class.new(widget: widget, current_user: user) }

    subject { service.before_update_in_transaction(params: params) }

    shared_examples 'work item and progress is unchanged' do
      it 'does not change work item progress value' do
        expect { subject }
          .to not_change { work_item_progress }
          .and not_change { work_item_current_value }
          .and not_change { work_item.updated_at }
      end

      it 'does not create notes' do
        expect { subject }.to not_change(work_item.notes, :count)
      end
    end

    shared_examples 'progress is updated' do |new_value|
      it 'updates work item progress value' do
        expect { subject }
          .to change { work_item_progress }.to(new_value).and change { work_item_current_value }.to(new_value)
      end

      it 'creates notes' do
        subject

        work_item_note = work_item.notes.last
        expect(work_item_note.note).to eq("changed progress to **#{new_value}**")
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

          context 'when widget does not exist in new type' do
            let(:params) { {} }

            before do
              allow(service).to receive(:new_type_excludes_widget?).and_return(true)
              work_item.progress = progress
            end

            it "removes the work item's progress" do
              expect { subject }.to change { work_item.reload.progress }.from(progress).to(nil)

              work_item_note = work_item.notes.last
              expect(work_item_note.note).to eq("removed the progress **5**")
            end
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

        context 'when progress is same as current value' do
          let(:params) { { progress: 5 } }

          it_behaves_like 'work item and progress is unchanged'
        end

        context 'when progress param is nil' do
          let(:params) { { progress: nil } }

          it_behaves_like 'raises a WidgetError' do
            let(:message) { "Progress is not a number, Current value can't be blank" }
          end
        end
      end
    end
  end
end
