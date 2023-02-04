# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::AutocompleteSourcesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group2) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group2) }
  let_it_be(:vulnerability) { create(:vulnerability, :with_finding, project: project) }

  before do
    sign_in(user)
  end

  describe '#epics', feature_category: :portfolio_management do
    context 'when epics feature is disabled' do
      it 'returns 404 status' do
        get :epics, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      describe '#epics' do
        it 'returns the correct response', :aggregate_failures do
          epic_json_response = {
            'iid' => epic.iid,
            'title' => epic.title,
            'reference' => epic.to_reference(epic)
          }

          get :epics, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response.count).to eq(1)
          expect(json_response.first).to include(epic_json_response)
        end
      end
    end
  end

  describe '#iterations', :freeze_time, feature_category: :team_planning do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:open_iteration) { create(:iteration, iterations_cadence: cadence) }
    let_it_be(:closed_iteration) { create(:iteration, :closed, iterations_cadence: cadence) }
    let_it_be(:other_iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group2)) }

    context 'when iterations feature is disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      it 'returns 404 status' do
        visit

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when iterations feature is enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      describe '#iterations' do
        it 'returns the correct response', :aggregate_failures do
          iteration_json_response = {
            'id' => open_iteration.id,
            'title' => open_iteration.display_text,
            'reference' => open_iteration.to_reference
          }

          visit

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response.count).to eq(1)
          expect(json_response.first).to include(iteration_json_response)
        end
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { visit }

        create(:iteration, iterations_cadence: cadence)

        expect { visit }.not_to exceed_all_query_limit(control)
      end
    end

    def visit
      get :iterations, params: { namespace_id: project.namespace, project_id: project }
    end
  end

  describe '#vulnerabilities', feature_category: :vulnerability_management do
    context 'when vulnerabilities feature is disabled' do
      it 'returns 404 status' do
        get :vulnerabilities, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when vulnerabilities feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
        project.add_developer(user)
      end

      describe '#vulnerabilities' do
        it 'returns the correct response', :aggregate_failures do
          get :vulnerabilities, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response.count).to eq(1)
          expect(json_response.first).to include(
            'id' => vulnerability.id, 'title' => vulnerability.title
          )
        end
      end
    end
  end
end
