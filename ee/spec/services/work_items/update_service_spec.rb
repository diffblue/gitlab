# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateService do
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project).tap { |proj| proj.add_developer(developer) } }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:spam_params) { double }
  let(:current_user) { developer }

  describe '#execute' do
    before do
      stub_spam_services
    end

    it_behaves_like 'work item widgetable service' do
      let(:widget_params) do
        {
          weight_widget: { weight: 1 }
        }
      end

      let(:service) do
        described_class.new(
          project: project,
          current_user: current_user,
          params: {},
          spam_params: spam_params,
          widget_params: widget_params
        )
      end

      let(:service_execute) { service.execute(work_item) }

      let(:supported_widgets) do
        [
          { klass: WorkItems::Widgets::WeightService::UpdateService, callback: :update, params: { weight: 1 } }
        ]
      end
    end
  end
end
