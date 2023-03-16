# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateService, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group).tap { |proj| proj.add_developer(developer) } }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:spam_params) { double }
  let(:current_user) { developer }

  describe '#execute' do
    let(:service) do
      described_class.new(
        container: project,
        current_user: current_user,
        params: {},
        spam_params: spam_params,
        widget_params: widget_params
      )
    end

    subject { service.execute(work_item) }

    before do
      stub_spam_services
    end

    it_behaves_like 'work item widgetable service' do
      let(:widget_params) do
        {
          weight_widget: { weight: 1 }
        }
      end

      let(:service_execute) { subject }

      let(:supported_widgets) do
        [
          {
            klass: WorkItems::Widgets::WeightService::UpdateService,
            callback: :before_update_callback, params: { weight: 1 }
          }
        ]
      end
    end

    context 'when updating widgets' do
      context 'for the weight widget' do
        let(:widget_params) { { weight_widget: { weight: new_weight } } }

        before do
          stub_licensed_features(issue_weights: true)

          work_item.update!(weight: 1)
        end

        context 'when weight is changed' do
          let(:new_weight) { nil }

          it "triggers 'issuableWeightUpdated' for issuable weight update subscription" do
            expect(GraphqlTriggers).to receive(:issuable_weight_updated).with(work_item).and_call_original

            subject
          end
        end

        context 'when weight remains unchanged' do
          let(:new_weight) { 1 }

          it "does not trigger 'issuableWeightUpdated' for issuable weight update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_weight_updated)

            subject
          end
        end

        context 'when weight widget param is not provided' do
          let(:widget_params) { {} }

          it "does not trigger 'issuableWeightUpdated' for issuable weight update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_weight_updated)

            subject
          end
        end
      end

      context 'for the iteration widget' do
        let_it_be(:cadence) { create(:iterations_cadence, group: group) }
        let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }

        let(:widget_params) { { iteration_widget: { iteration: new_iteration } } }

        before do
          stub_licensed_features(iterations: true)

          work_item.update!(iteration: nil)
        end

        context 'when iteration is changed' do
          let(:new_iteration) { iteration }

          it "triggers 'issuableIterationUpdated' for issuable iteration update subscription" do
            expect(GraphqlTriggers).to receive(:issuable_iteration_updated).with(work_item).and_call_original

            subject
          end
        end

        context 'when iteration remains unchanged' do
          let(:new_iteration) { nil }

          it "does not trigger 'issuableIterationUpdated' for issuable iteration update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_iteration_updated)

            subject
          end
        end

        context 'when iteration widget param is not provided' do
          let(:widget_params) { {} }

          it "does not trigger 'issuableIterationUpdated' for issuable iteration update subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_iteration_updated)

            subject
          end
        end
      end

      context 'for the health_status widget' do
        let(:widget_params) { { health_status_widget: { health_status: new_health_status } } }

        before do
          stub_licensed_features(issuable_health_status: true)

          work_item.update!(health_status: :needs_attention)
        end

        context 'when health_status is changed' do
          let(:new_health_status) { :on_track }

          it "triggers 'issuableHealthStatusUpdated' subscription" do
            expect(GraphqlTriggers).to receive(:issuable_health_status_updated).with(work_item).and_call_original

            subject
          end
        end

        context 'when health_status remains unchanged' do
          let(:new_health_status) { :needs_attention }

          it "does not trigger 'issuableHealthStatusUpdated' subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_health_status_updated)

            subject
          end
        end

        context 'when health_status widget param is not provided' do
          let(:widget_params) { {} }

          it "does not trigger 'issuableHealthStatusUpdated' subscription" do
            expect(GraphqlTriggers).not_to receive(:issuable_health_status_updated)

            subject
          end
        end
      end
    end
  end
end
