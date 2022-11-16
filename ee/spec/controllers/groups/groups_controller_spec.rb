# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, feature_category: :subgroups do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'external authorization' do
    before_all do
      group.add_owner(user)
    end

    context 'with external authorization service enabled' do
      before do
        enable_external_authorization_service_check
      end

      describe 'PUT #update' do
        context 'no license' do
          it 'does not update the file_template_project_id successfully' do
            project = create(:project, group: group)

            stub_licensed_features(custom_file_templates_for_namespace: false)

            expect do
              post :update, params: { id: group.to_param, group: { file_template_project_id: project.id } }
            end.not_to change { group.reload.file_template_project_id }
          end
        end

        context 'with license' do
          it 'updates the file_template_project_id successfully' do
            project = create(:project, group: group)

            stub_licensed_features(custom_file_templates_for_namespace: true)

            expect do
              post :update, params: { id: group.to_param, group: { file_template_project_id: project.id } }
            end.to change { group.reload.file_template_project_id }.to(project.id)
          end

          context 'with insights feature' do
            let(:project) { create(:project, group: group) }

            before do
              stub_licensed_features(insights: true)
            end

            it 'updates insight project_id successfully' do
              post :update, params: { id: group.to_param, group: { insight_attributes: { project_id: project.id } } }

              expect(group.reload.insight.project).to eq(project)
            end

            it 'removes insight successfully' do
              insight = group.create_insight(project: project)

              post :update, params: { id: group.to_param, group: { insight_attributes: { id: insight.id, project_id: '' } } }

              expect(group.reload.insight).to be_nil
            end
          end
        end
      end
    end
  end

  context 'with sso enforcement enabled' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }
    let_it_be(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
    let_it_be(:guest_user) { identity.user }

    before_all do
      group.add_guest(guest_user)
    end

    before do
      stub_licensed_features(group_saml: true)
      sign_in(guest_user)
    end

    context 'without SAML session' do
      it 'prevents access to group resources' do
        get :show, params: { id: group }

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to match(%r{groups/#{group.to_param}/-/saml/sso\?redirect=.+&token=})
      end
    end

    context 'with active SAML session' do
      before do
        Gitlab::Session.with_session(@request.session) do
          Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session
        end
      end

      it 'allows access to group resources' do
        get :show, params: { id: group }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe '"group information content" preference behaviour' do
    describe 'GET #show' do
      subject { get :show, params: { id: group.to_param }, format: format }

      let(:format) { :html }

      context 'with user having proper permissions and feature enabled' do
        before_all do
          group.add_developer(user)
        end

        before do
          stub_licensed_features(security_dashboard: true)
          sign_in(user)
        end

        context 'with group view set as default' do
          it 'renders the expected template' do
            expect(subject).to render_template('groups/show')
          end
        end

        context 'with group view set to security dashboard' do
          let(:user) { create(:user, group_view: :security_dashboard) }

          context 'in HTML format' do
            it 'redirects to the security dashboard' do
              expect(subject).to redirect_to(group_security_dashboard_url(group))
            end
          end

          context 'in Atom format' do
            let(:format) { :atom }

            it 'does not redirect to the security dashboard' do
              expect(subject).to render_template('groups/show')
            end
          end
        end
      end
    end

    describe 'GET #details' do
      subject { get :details, params: { id: group.to_param } }

      context 'with user having proper permissions and feature enabled' do
        before_all do
          group.add_developer(user)
        end

        before do
          stub_licensed_features(security_dashboard: true)
          sign_in(user)
        end

        context 'with group view set to security dashboard' do
          let(:user) { create(:user, group_view: :security_dashboard) }

          it 'does not redirect to the security dashboard' do
            expect(subject).not_to redirect_to(group_security_dashboard_url(group))
          end
        end
      end
    end
  end
end
