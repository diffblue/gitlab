# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Analytics (JavaScript fixtures)', :sidekiq_inline do
  describe Groups::Analytics::CycleAnalytics::StagesController, type: :controller do
    include_context '[EE] Analytics fixtures shared context'

    render_views

    it 'analytics/value_stream_analytics/stages.json' do
      get(:index, params: { group_id: group.name, value_stream_id: value_stream.id }, format: :json)

      expect(response).to be_successful
    end

    it "analytics/value_stream_analytics/stages/label-based-stage/records.json" do
      get(:records, params: params.merge({ id: label_based_stage.id }), format: :json)

      expect(response).to be_successful
    end

    it "analytics/value_stream_analytics/stages/label-based-stage/median.json" do
      get(:median, params: params.merge({ id: label_based_stage.id }), format: :json)

      expect(response).to be_successful
    end

    it "analytics/value_stream_analytics/stages/label-based-stage/count.json" do
      get(:count, params: params.merge({ id: label_based_stage.id }), format: :json)

      expect(response).to be_successful
    end
  end
end
