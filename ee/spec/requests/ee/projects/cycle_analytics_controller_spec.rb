# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CycleAnalyticsController, feature_category: :product_analytics_data_management do
  let_it_be(:project) { create(:project, namespace: create(:group)) }
  let_it_be(:user) { create(:user) }
  let_it_be(:value_stream) { create(:cycle_analytics_value_stream, namespace: project.project_namespace) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'with project and value stream id params' do
    it 'builds request params with project and value stream' do
      expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::RequestParams) do |instance|
        expect(instance).to have_attributes(namespace: project.project_namespace, value_stream: value_stream)
      end

      get project_cycle_analytics_path(project, value_stream_id: value_stream)
    end
  end

  context 'when extra query params are given' do
    let(:extra_query_params) { { weight: '3', epic_id: '1', iteration_id: '2', my_reaction_emoji: 'thumbsup' } }

    context 'when not licensed' do
      it 'does not expose unsupported query params' do
        get project_cycle_analytics_path(project, value_stream_id: value_stream, **extra_query_params)

        expect(body).not_to include('data-weight')
        expect(body).not_to include('data-epic-id')
        expect(body).not_to include('data-iteration-id')
        expect(body).not_to include('data-my-reaction-emoji')
      end
    end

    context 'when licensed' do
      before do
        stub_licensed_features(cycle_analytics_for_projects: true)
      end

      it 'expsoes all query params' do
        get project_cycle_analytics_path(project, value_stream_id: value_stream, **extra_query_params)

        expect(body).to include('data-weight="3"')
        expect(body).to include('data-epic-id="1"')
        expect(body).to include('data-iteration-id="2"')
        expect(body).to include('data-my-reaction-emoji="thumbsup"')
      end
    end
  end
end
