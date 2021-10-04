# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ThreatMonitoringController do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:alert) { create(:alert_management_alert, :threat_monitoring, project: project) }
  let_it_be(:user) { create(:user) }

  describe 'GET show' do
    subject { get :show, params: { namespace_id: project.namespace, project_id: project } }

    context 'with authorized user' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(threat_monitoring: true)
        end

        it 'renders the show template' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(threat_monitoring: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        sign_in(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(threat_monitoring: true)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with anonymous user' do
      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET new' do
    subject { get :new, params: { namespace_id: project.namespace, project_id: project } }

    context 'with authorized user' do
      before do
        stub_licensed_features(threat_monitoring: true)
        project.add_developer(user)
        sign_in(user)
      end

      it 'redirects to policies#new page' do
        subject

        expect(response).to redirect_to(new_project_security_policy_path(project))
      end
    end

    context 'with unauthorized user' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with anonymous user' do
      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET edit' do
    subject do
      get :edit, params: { namespace_id: project.namespace, project_id: project, id: 'policy', environment_id: environment_id, kind: kind }
    end

    let_it_be(:environment) { create(:environment, :with_review_app, project: project) }

    let(:environment_id) { environment.id }
    let(:kind) { 'CiliumNetworkPolicy' }

    context 'with authorized user' do
      let(:service) { instance_double('NetworkPolicies::FindResourceService', execute: ServiceResponse.success(payload: policy)) }
      let(:policy) do
        Gitlab::Kubernetes::CiliumNetworkPolicy.new(
          name: 'policy',
          namespace: 'another',
          selector: { matchLabels: { role: 'db' } },
          ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }]
        )
      end

      before do
        stub_licensed_features(threat_monitoring: true)

        allow(NetworkPolicies::FindResourceService).to(
          receive(:new)
            .with(resource_name: 'policy', environment: environment, kind: Gitlab::Kubernetes::CiliumNetworkPolicy::KIND)
            .and_return(service)
        )

        project.add_developer(user)
        sign_in(user)
      end

      it 'redirects to policies#edit page' do
        subject

        expect(response).to redirect_to(
          edit_project_security_policy_path(
            project,
            environment_id: environment_id,
            id: 'policy',
            type: :container_policy,
            kind: kind
          )
        )
      end
    end

    context 'with unauthorized user' do
      before do
        sign_in(user)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with anonymous user' do
      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET threat monitoring alerts' do
    let(:alert_iid) { alert.iid }

    subject { get :alert_details, params: { namespace_id: project.namespace, project_id: project, iid: alert_iid } }

    context 'with authorized user' do
      before do
        project.add_developer(user)
        sign_in(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(threat_monitoring: true)
        end

        it 'renders the show template' do
          subject

          expect(response).to render_template(:alert_details)
        end

        context 'when id is invalid' do
          let(:alert_iid) { nil }

          it 'raises an error' do
            expect { subject }.to raise_error(ActionController::UrlGenerationError)
          end
        end

        context 'when id is not found' do
          let(:alert_iid) { non_existing_record_id }

          it 'renders not found' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(threat_monitoring: false)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        sign_in(user)
      end

      context 'when feature is available' do
        before do
          stub_licensed_features(threat_monitoring: true)
        end

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with anonymous user' do
      it 'returns 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
