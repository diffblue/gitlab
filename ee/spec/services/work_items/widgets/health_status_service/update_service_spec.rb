# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::HealthStatusService::UpdateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project, author: user, health_status: nil) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::HealthStatus) } }
  let(:new_health_status) { :on_track }
  let(:params) { { health_status: new_health_status } }

  describe '#update' do
    let(:service) { described_class.new(widget: widget, current_user: user) }

    subject(:update_health_status) { service.before_update_callback(params: params) }

    before do
      stub_licensed_features(issuable_health_status: true)
    end

    shared_examples 'health_status is unchanged' do
      it 'does not change the health_status of the work item' do
        expect { update_health_status }
          .to not_change { work_item.health_status }
      end
    end

    context 'when it has issuable_health_status license' do
      context 'when health_status param is not present' do
        let(:params) { {} }

        it_behaves_like 'health_status is unchanged'
      end

      context 'when user can not admin work item' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'health_status is unchanged'
      end

      context 'when user can admin the work item' do
        before do
          project.add_reporter(user)
        end

        it 'sets the health_status for the work item and triggers subscription' do
          update_health_status

          expect(work_item.health_status).to eq('on_track')
        end

        context 'when widget does not exist in new type' do
          let(:params) { {} }

          before do
            allow(service).to receive(:new_type_excludes_widget?).and_return(true)
            work_item.health_status = 'on_track'
          end

          it "resets the work item's health status" do
            expect { subject }.to change { work_item.health_status }.from('on_track').to(nil)
          end
        end
      end
    end
  end
end
