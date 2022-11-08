# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::VulnerabilitiesController do
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, namespace: group) }
  let_it_be(:user)    { create(:user) }

  render_views

  before do
    group.add_developer(user)
    stub_licensed_features(security_dashboard: true)
    sign_in(user)
  end

  describe 'GET #new' do
    let(:request_new_vulnerability_page) { get :new, params: { namespace_id: project.namespace, project_id: project } }

    before do
      allow(controller).to receive(:can?).and_call_original
      allow(controller).to receive(:can?).with(controller.current_user, :create_vulnerability, project).and_return(can_create_vulnerability)
    end

    include_context '"Security & Compliance" permissions' do
      let(:valid_request) { request_new_vulnerability_page }
      let(:can_create_vulnerability) { true }
    end

    it 'checks if the user can create a vulnerability' do
      request_new_vulnerability_page

      expect(controller).to have_received(:can?).with(controller.current_user, :create_vulnerability, project)
    end

    context 'when user can create vulnerability' do
      let(:can_create_vulnerability) { true }

      it 'renders the add new finding page' do
        request_new_vulnerability_page

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when user can not create vulnerability' do
      let(:can_create_vulnerability) { false }

      it 'renders 404 page not found' do
        request_new_vulnerability_page

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #show' do
    let_it_be(:pipeline) { create(:ci_pipeline, sha: project.commit.id, project: project, user: user) }
    let_it_be(:vulnerability) { create(:vulnerability, project: project) }

    subject(:show_vulnerability) { get :show, params: { namespace_id: project.namespace, project_id: project, id: vulnerability.id } }

    include_context '"Security & Compliance" permissions' do
      let(:valid_request) { show_vulnerability }
    end

    context "when there's an attached pipeline" do
      let_it_be(:finding) { create(:vulnerabilities_finding, :with_pipeline, vulnerability: vulnerability) }

      it 'renders the vulnerability page' do
        show_vulnerability

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to have_text(vulnerability.title)
      end

      it 'renders the vulnerability component' do
        show_vulnerability

        expect(response.body).to have_css("#js-vulnerability-main")
      end
    end

    context "when there's no attached pipeline" do
      let_it_be(:finding) { create(:vulnerabilities_finding, vulnerability: vulnerability, project: vulnerability.project) }

      it 'renders the vulnerability page' do
        show_vulnerability

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to have_text(vulnerability.title)
      end
    end
  end

  describe 'GET #discussions' do
    let_it_be(:vulnerability) { create(:vulnerability, project: project, author: user) }
    let_it_be(:discussion_note) { create(:discussion_note_on_vulnerability, noteable: vulnerability, project: vulnerability.project) }

    subject(:show_vulnerability_discussion_list) { get :discussions, params: { namespace_id: project.namespace, project_id: project, id: vulnerability } }

    include_context '"Security & Compliance" permissions' do
      let(:valid_request) { show_vulnerability_discussion_list }
    end

    it 'renders discussions' do
      show_vulnerability_discussion_list

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('entities/discussions')
      expect(json_response.pluck('id')).to eq([discussion_note.discussion_id])
    end
  end
end
