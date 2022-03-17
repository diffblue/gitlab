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

  describe '#epics' do
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

  describe '#vulnerabilities' do
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
