# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CycleAnalyticsController, feature_category: :product_analytics do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'with project and value stream id params' do
    let(:value_stream) { create(:cycle_analytics_value_stream, namespace: project.project_namespace) }

    it 'builds request params with project and value stream' do
      expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::RequestParams) do |instance|
        expect(instance).to have_attributes(namespace: project.project_namespace, value_stream: value_stream)
      end

      get project_cycle_analytics_path(project, value_stream_id: value_stream)
    end
  end
end
