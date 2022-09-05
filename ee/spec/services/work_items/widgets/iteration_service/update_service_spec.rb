# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::IterationService::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }
  let_it_be(:other_iteration) { create(:iteration, iterations_cadence: cadence) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project, author: user, iteration: iteration) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Iteration) } }
  let(:params) { { iteration: other_iteration } }

  describe '#update' do
    subject { described_class.new(widget: widget, current_user: user).before_update_callback(params: params) }

    before do
      stub_licensed_features(iterations: true)
    end

    shared_examples 'iteration is unchanged' do
      it 'does not change the iteration of the work item' do
        expect { subject }
          .to not_change { work_item.iteration }
      end
    end

    context 'when iteration param is not present' do
      let(:params) { {} }

      it_behaves_like 'iteration is unchanged'
    end

    context 'when user can only update but not admin the work item' do
      before do
        project.add_guest(user)
      end

      it_behaves_like 'iteration is unchanged'
    end

    context 'when user can admin the work item' do
      before do
        project.add_reporter(user)
      end

      where(:new_iteration) do
        [[lazy { other_iteration }], [nil]]
      end

      with_them do
        let(:params) { { iteration: new_iteration } }

        it 'sets the iteration for the work item' do
          expect { subject }
            .to change(work_item, :iteration).to(new_iteration)
        end
      end

      context "when iteration is from neither the work item's group nor its ancestors" do
        let_it_be(:other_cadence) { create(:iterations_cadence, group: create(:group)) }
        let_it_be(:other_iteration) { create(:iteration, iterations_cadence: other_cadence) }

        let(:params) { { iteration: other_iteration } }

        it 'does not set the iteration for the work item' do
          expect { subject }
            .to not_change(work_item, :iteration)
        end
      end
    end
  end
end
