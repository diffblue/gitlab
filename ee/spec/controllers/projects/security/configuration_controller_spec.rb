# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationController do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, :repository, namespace: group) }

  before do
    stub_licensed_features(security_dashboard: true)
    group.add_developer(user)
  end

  describe 'GET #show', feature_category: :static_application_security_testing do
    using RSpec::Parameterized::TableSyntax

    subject(:request) { get :show, params: { namespace_id: project.namespace, project_id: project } }

    let(:user) { create(:user) }

    render_views

    where(:user_role, :security_dashboard_enabled, :status, :selector) do
      :guest     | false | :forbidden | nil
      :guest     | true  | :forbidden | nil
      :developer | false | :ok        | '#js-security-configuration'
      :developer | true  | :ok        | '#js-security-configuration'
    end

    with_them do
      before do
        stub_licensed_features(security_dashboard: security_dashboard_enabled)
        group.send("add_#{user_role}", user)
        sign_in(user)
      end

      include_context '"Security and Compliance" permissions' do
        let(:valid_request) { request }
      end

      it 'responds with the correct status' do
        request

        expect(response).to have_gitlab_http_status(status)

        unless selector.nil?
          expect(response).to render_template(:show)
          expect(response.body).to have_css(selector)
        end
      end
    end

    context 'with developer and security dashboard feature enabled' do
      before do
        stub_licensed_features(security_dashboard: true)

        group.add_developer(user)
        sign_in(user)
      end

      it 'responds in json format when requested' do
        get :show, params: { namespace_id: project.namespace, project_id: project, format: :json }

        types = %w(sast sast_iac dast dast_profiles dependency_scanning container_scanning cluster_image_scanning secret_detection coverage_fuzzing license_scanning api_fuzzing corpus_management breach_and_attack_simulation)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['features'].map { |f| f['type'] }).to match_array(types)
        expect(json_response['auto_fix_enabled']).to include({ 'dependency_scanning' => true, 'container_scanning' => true })
      end

      it "renders data on the project's security configuration" do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response.body).to have_css(
          'div#js-security-configuration'\
            "[data-auto-devops-help-page-path=\"#{help_page_path('topics/autodevops/index')}\"]"\
            "[data-help-page-path=\"#{help_page_path('user/application_security/index')}\"]"\
            "[data-latest-pipeline-path=\"#{help_page_path('ci/pipelines/index')}\"]"
        )
      end

      context 'when the latest pipeline used Auto DevOps' do
        let!(:pipeline) do
          create(
            :ci_pipeline,
            :auto_devops_source,
            project: project,
            ref: project.default_branch,
            sha: project.commit.sha
          )
        end

        it 'reports that Auto DevOps is enabled' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to have_css(
            'div#js-security-configuration'\
              '[data-auto-devops-enabled]'\
              "[data-auto-devops-help-page-path=\"#{help_page_path('topics/autodevops/index')}\"]"\
              "[data-help-page-path=\"#{help_page_path('user/application_security/index')}\"]"\
              "[data-latest-pipeline-path=\"#{project_pipeline_path(project, pipeline)}\"]"
          )
        end
      end
    end
  end

  describe 'POST #auto_fix', feature_category: :software_composition_analysis do
    subject(:request) { post :auto_fix, params: params }

    let_it_be(:maintainer) { create(:user) }
    let_it_be(:developer) { create(:user) }

    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        feature: feature,
        enabled: false
      }
    end

    before do
      project.add_maintainer(maintainer)
      project.add_developer(developer)
      sign_in(user)
    end

    context 'with feature enabled' do
      let(:feature) { :dependency_scanning }

      before do
        request
      end

      context 'with sufficient permissions' do
        let(:user) { maintainer }

        context 'with setup feature param' do
          let(:feature) { :dependency_scanning }

          it 'processes request and updates setting' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(project.security_setting.reload.auto_fix_dependency_scanning).to be_falsey
            expect(json_response['dependency_scanning']).to be(false)
          end
        end

        context 'without setup feature param' do
          let(:feature) { '' }

          it 'processes request and updates setting' do
            setting = project.reload.security_setting

            expect(response).to have_gitlab_http_status(:ok)
            expect(setting.auto_fix_dependency_scanning).to be_falsey
            expect(setting.auto_fix_dast).to be_falsey
            expect(json_response['dependency_scanning']).to be(false)
            expect(json_response['container_scanning']).to be(false)
          end
        end

        context 'without processable feature' do
          let(:feature) { :dep_scan }

          it 'does not pass validation' do
            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(project.security_setting.auto_fix_dependency_scanning).to be_truthy
          end
        end
      end

      context 'without sufficient permissions' do
        let(:user) { developer }
        let(:feature) { '' }

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end
    end

    context 'with feature disabled' do
      let(:user) { maintainer }
      let(:feature) { :dependency_scanning }

      before do
        stub_feature_flags(security_auto_fix: false)

        request
      end

      it { expect(response).to have_gitlab_http_status(:not_found) }
    end
  end
end
