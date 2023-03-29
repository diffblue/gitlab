# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::IterationService::UpdateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project, author: user) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Iteration) } }

  describe '#before_update_callback' do
    let(:service) { described_class.new(widget: widget, current_user: user) }

    subject { service.before_update_callback(params: params) }

    before do
      stub_licensed_features(iterations: true)
    end

    it_behaves_like 'iteration change is handled' do
      context 'when user can admin the work item' do
        let_it_be(:other_iteration) { create(:iteration, iterations_cadence: cadence) }

        before do
          work_item.update!(iteration: iteration)
          project.add_reporter(user)
        end

        where(:new_iteration) do
          [[lazy { other_iteration }], [nil]]
        end

        with_them do
          let(:params) { { iteration: new_iteration } }

          it 'sets a new iteration value for the work item' do
            expect { subject }
              .to change(work_item, :iteration).to(new_iteration).from(iteration)
          end
        end

        context 'when widget does not exist in new type' do
          let(:params) { {} }

          before do
            allow(service).to receive(:new_type_excludes_widget?).and_return(true)
            work_item.iteration = iteration
          end

          it "resets the work item's iteration" do
            expect { subject }.to change(work_item, :iteration).from(iteration).to(nil)
          end
        end
      end
    end
  end
end
