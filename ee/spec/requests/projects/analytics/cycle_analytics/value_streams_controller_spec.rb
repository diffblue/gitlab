# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::ValueStreamsController, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, refind: true) { create(:project, group: group) }
  let_it_be(:namespace) { project.project_namespace }

  let(:path_prefix) { %i[namespace project] }
  let(:params) { { namespace_id: group.to_param, project_id: project.to_param } }
  let(:license_name) { :cycle_analytics_for_projects }

  it_behaves_like 'value stream controller actions' do
    describe 'GET index' do
      subject(:request) { get path_for(%i[analytics cycle_analytics value_streams]) }

      context 'when user is member of the project' do
        context 'when not licensed' do
          before do
            stub_licensed_features(license_name => false)
          end

          it 'succeeds and returns the default value stream' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
            expect(json_response.first['id']).to eq('default')
          end
        end
      end
    end

    context 'when the project has lower visibility level' do
      subject(:request) { delete path_for(value_streams.first) }

      before do
        project.update!(visibility_level: Project::PUBLIC)
      end

      it 'disallows deleting the record' do
        login_as(another_user)

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
