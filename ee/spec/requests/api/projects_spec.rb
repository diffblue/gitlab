# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Projects, :aggregate_failures, feature_category: :projects do
  include ExternalAuthorizationServiceHelpers
  include StubRequests

  let(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }

  let(:project) { create(:project, namespace: user.namespace) }

  shared_examples 'inaccessable by reporter role and lower' do
    context 'for reporter' do
      before do
        reporter = create(:user)
        project.add_reporter(reporter)

        get api(path, reporter)
      end

      it 'returns 403 response' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'for guest' do
      before do
        guest = create(:user)
        project.add_guest(guest)

        get api(path, guest)
      end

      it 'returns 403 response' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'for anonymous' do
      before do
        anonymous = create(:user)

        get api(path, anonymous)
      end

      it 'returns 403 response' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /projects' do
    it 'does not break on license checks' do
      enable_namespace_license_check!

      create(:project, :private, namespace: user.namespace)
      create(:project, :public, namespace: user.namespace)

      get api('/projects', user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'filters by verification flags' do
      let(:project1) { create(:project, namespace: user.namespace) }

      it 'filters by :repository_verification_failed' do
        create(:repository_state, :repository_failed, project: project)
        create(:repository_state, :wiki_failed, project: project1)

        get api('/projects', user), params: { repository_checksum_failed: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq project.id
      end

      it 'filters by :wiki_verification_failed' do
        create(:repository_state, :wiki_failed, project: project)
        create(:repository_state, :repository_failed, project: project1)

        get api('/projects', user), params: { wiki_checksum_failed: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq project.id
      end
    end

    context 'when there are several projects owned by groups' do
      let_it_be(:admin) { create(:admin) }

      it 'avoids N+1 queries', :use_sql_query_cache do
        create(:project, :public, namespace: create(:group))

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api('/projects', admin)
        end

        create_list(:project, 2, :public, namespace: create(:group))

        expect do
          get api('/projects', admin)
        end.not_to exceed_all_query_limit(control.count)
      end
    end
  end

  describe 'GET /projects/:id' do
    subject { get api("/projects/#{project.id}", user) }

    context 'with external authorization' do
      let(:project) do
        create(:project,
               namespace: user.namespace,
               external_authorization_classification_label: 'the-label')
      end

      before do
        stub_licensed_features(external_authorization_service_api_management: true)
      end

      context 'when the user has access to the project' do
        before do
          external_service_allow_access(user, project)
        end

        it 'includes the label in the response' do
          get api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['external_authorization_classification_label']).to eq('the-label')
        end
      end

      context 'when the external service denies access' do
        before do
          external_service_deny_access(user, project)
        end

        it 'returns a 404' do
          get api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'it does not return the label when the feature is not available' do
        before do
          stub_licensed_features(external_authorization_service_api_management: false)
        end

        it 'does not include the label in the response' do
          get api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['external_authorization_classification_label']).to be_nil
        end
      end

      context 'with ip restriction' do
        let(:group) { create :group, :private }

        before do
          create(:ip_restriction, group: group)
          group.add_maintainer(user)
          project.update!(namespace: group)
        end

        context 'when the group_ip_restriction feature is not available' do
          before do
            stub_licensed_features(group_ip_restriction: false)
          end

          it 'returns 200' do
            get api("/projects/#{project.id}", user)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when the group_ip_restriction feature is available' do
          before do
            stub_licensed_features(group_ip_restriction: true)
          end

          it 'returns 404 for request from ip not in the range' do
            get api("/projects/#{project.id}", user)

            expect(response).to have_gitlab_http_status(:not_found)
          end

          it 'returns 200 for request from ip in the range' do
            get api("/projects/#{project.id}", user), headers: { 'REMOTE_ADDR' => '192.168.0.0' }

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    describe 'compliance_frameworks attribute' do
      context 'when compliance_framework feature is available' do
        context 'when project has a compliance framework' do
          before do
            project.update!(compliance_framework_setting: create(:compliance_framework_project_setting, :sox))
            get api("/projects/#{project.id}", user)
          end

          it 'exposes framework names as array of strings' do
            expect(json_response['compliance_frameworks']).to contain_exactly(project.compliance_framework_setting.compliance_management_framework.name)
          end
        end

        context 'when project has no compliance framework' do
          before do
            get api("/projects/#{project.id}", user)
          end

          it 'returns an empty array' do
            expect(json_response['compliance_frameworks']).to eq([])
          end
        end
      end
    end

    context 'project soft-deletion' do
      let(:project) do
        create(:project, :public, archived: true, marked_for_deletion_at: 1.day.ago, deleting_user: user)
      end

      describe 'marked_for_deletion_at attribute' do
        it 'exposed when the feature is available' do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)

          subject

          expect(json_response).to have_key 'marked_for_deletion_at'
          expect(Date.parse(json_response['marked_for_deletion_at'])).to eq(project.marked_for_deletion_at)
        end

        it 'not exposed when the feature is not available' do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)

          subject

          expect(json_response).not_to have_key 'marked_for_deletion_at'
        end
      end

      describe 'marked_for_deletion_on attribute' do
        it 'exposed when the feature is available' do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)

          subject

          expect(json_response).to have_key 'marked_for_deletion_on'
          expect(Date.parse(json_response['marked_for_deletion_on'])).to eq(project.marked_for_deletion_at)
        end

        it 'not exposed when the feature is not available' do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)

          subject

          expect(json_response).not_to have_key 'marked_for_deletion_on'
        end
      end
    end

    context 'issuable default templates' do
      let(:project) { create(:project, :public) }

      context 'when feature is available' do
        before do
          stub_licensed_features(issuable_default_templates: true)
        end

        it 'returns issuable default templates' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to have_key 'issues_template'
          expect(json_response).to have_key 'merge_requests_template'
        end

        context 'when user does not have permission to see issues' do
          let(:project) { create(:project, :public, :issues_private) }

          it 'does not return issue default templates' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).not_to have_key 'issues_template'
            expect(json_response).to have_key 'merge_requests_template'
          end
        end

        context 'when user does not have permission to see merge requests' do
          let(:project) { create(:project, :public, :merge_requests_private) }

          it 'does not return merge request default templates' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to have_key 'issues_template'
            expect(json_response).not_to have_key 'merge_requests_template'
          end
        end
      end

      context 'issuable default templates feature not available' do
        before do
          stub_licensed_features(issuable_default_templates: false)
        end

        it 'does not return issuable default templates' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).not_to have_key 'issues_template'
          expect(json_response).not_to have_key 'merge_requests_template'
        end
      end
    end

    context 'merge pipelines feature is available' do
      before do
        stub_licensed_features(merge_pipelines: true)
      end

      it 'returns merge pipelines enabled flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to have_key 'merge_pipelines_enabled'
      end
    end

    context 'merge pipelines feature not available' do
      before do
        stub_licensed_features(merge_pipelines: false)
      end

      it 'does not return merge pipelines enabled flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'merge_pipelines_enabled'
      end
    end

    context 'when external_status_checks is available' do
      before do
        stub_licensed_features(external_status_checks: true)
      end

      it 'returns only_allow_merge_if_all_status_checks_passed flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to have_key 'only_allow_merge_if_all_status_checks_passed'
      end
    end

    context 'when external_status_checks not available' do
      before do
        stub_licensed_features(external_status_checks: false)
      end

      it 'does not return only_allow_merge_if_all_status_checks_passed enabled flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'only_allow_merge_if_all_status_checks_passed'
      end
    end

    context 'merge trains feature is available' do
      before do
        stub_licensed_features(merge_pipelines: true, merge_trains: true)
        project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
        stub_feature_flags(disable_merge_trains: false)
      end

      it 'returns merge trains enabled flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to have_key 'merge_trains_enabled'
      end
    end

    context 'merge trains feature not available' do
      before do
        stub_licensed_features(merge_trains: false)
      end

      it 'does not return merge trains enabled flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'merge_trains_enabled'
      end
    end

    context 'when protected_environments is available' do
      before do
        stub_licensed_features(protected_environments: true)
      end

      it 'returns allow_pipeline_trigger_approve_deployment flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to have_key 'allow_pipeline_trigger_approve_deployment'
      end
    end

    context 'when protected_environments is not available' do
      before do
        stub_licensed_features(protected_environments: false)
      end

      it 'does not returns allow_pipeline_trigger_approve_deployment flag' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'allow_pipeline_trigger_approve_deployment'
      end
    end
  end

  # Assumes the following variables are defined:
  # group
  # project
  # new_project_name
  # api_call
  shared_examples 'creates projects with templates' do
    before do
      group.add_maintainer(user)
      stub_licensed_features(custom_project_templates: true)
      stub_ee_application_setting(custom_project_templates_group_id: group.id)
    end

    it 'creates a project using a template' do
      expect(ProjectExportWorker).to receive(:perform_async).and_call_original

      Sidekiq::Testing.fake! do
        expect { api_call }.to change { Project.count }.by(1)
      end

      expect(response).to have_gitlab_http_status(:created)

      project = Project.find(json_response['id'])
      expect(project.name).to eq(new_project_name)
    end

    it 'returns a 400 error for an invalid template name' do
      project_params.delete(:template_project_id)
      project_params[:template_name] = 'bogus-template'

      expect { api_call }.not_to change { Project.count }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['template_name']).to eq(["'bogus-template' is unknown or invalid"])
    end

    it 'returns a 400 error for an invalid template ID' do
      project_params.delete(:template_name)
      new_project = create(:project)
      project_params[:template_project_id] = new_project.id

      expect { api_call }.not_to change { Project.count }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['template_project_id']).to eq(["#{new_project.id} is unknown or invalid"])
    end
  end

  shared_context 'base instance template models' do
    let(:group) { create(:group) }
    let!(:project) { create(:project, :public, namespace: group) }
    let(:new_project_name) { "project-#{SecureRandom.hex}" }
  end

  shared_context 'instance template name' do
    include_context 'base instance template models'

    let(:project_params) do
      {
        template_name: project.name,
        name: new_project_name,
        path: new_project_name,
        use_custom_template: true,
        namespace_id: group.id
      }
    end
  end

  shared_context 'instance template ID' do
    include_context 'base instance template models'

    let(:project_params) do
      {
        template_project_id: project.id,
        name: new_project_name,
        path: new_project_name,
        use_custom_template: true,
        namespace_id: group.id
      }
    end
  end

  shared_context 'base group template models' do
    let(:parent_group) { create(:group) }
    let(:subgroup) { create(:group, :public, parent: parent_group) }
    let(:group) { subgroup }
    let!(:project) { create(:project, :public, namespace: subgroup) }
    let(:new_project_name) { "project-#{SecureRandom.hex}" }
  end

  shared_context 'group template name' do
    include_context 'base group template models'

    let(:project_params) do
      {
        template_name: project.name,
        name: new_project_name,
        path: new_project_name,
        use_custom_template: true,
        group_with_project_templates_id: subgroup.id,
        namespace_id: subgroup.id
      }
    end
  end

  shared_context 'group template ID' do
    include_context 'base group template models'

    let(:project_params) do
      {
        template_project_id: project.id,
        name: new_project_name,
        path: new_project_name,
        use_custom_template: true,
        group_with_project_templates_id: subgroup.id,
        namespace_id: subgroup.id
      }
    end
  end

  describe 'GET /projects/:id/users' do
    shared_examples_for 'project users response' do
      it 'returns the project users' do
        get api("/projects/#{project.id}/users", current_user)

        user = project.namespace.owner

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)

        first_user = json_response.first
        expect(first_user['username']).to eq(user.username)
        expect(first_user['name']).to eq(user.name)
      end

      context 'when the gitlab_employee_badge flag is off' do
        it 'does not expose the is_gitlab_employee attribute on the user' do
          stub_feature_flags(gitlab_employee_badge: false)

          get api("/projects/#{project.id}/users", current_user)

          expect(json_response.first.keys).to contain_exactly(*%w[name username id state avatar_url web_url])
        end
      end

      context 'when the gitlab_employee_badge flag is on but we are not on gitlab.com' do
        it 'does not expose the is_gitlab_employee attribute on the user' do
          stub_feature_flags(gitlab_employee_badge: true)
          allow(Gitlab).to receive(:com?).and_return(false)

          get api("/projects/#{project.id}/users", current_user)

          expect(json_response.first.keys).to contain_exactly(*%w[name username id state avatar_url web_url])
        end
      end

      context 'when the gitlab_employee_badge flag is on and we are on gitlab.com' do
        it 'exposes the is_gitlab_employee attribute on the user' do
          stub_feature_flags(gitlab_employee_badge: true)
          allow(Gitlab).to receive(:com?).and_return(true)

          get api("/projects/#{project.id}/users", current_user)

          expect(json_response.first.keys).to contain_exactly(*%w[name username id state avatar_url web_url is_gitlab_employee])
        end
      end
    end

    context 'when unauthenticated' do
      it_behaves_like 'project users response' do
        let(:project) { create(:project, :public) }
        let(:current_user) { nil }
      end
    end

    context 'when authenticated' do
      context 'valid request' do
        it_behaves_like 'project users response' do
          let(:current_user) { user }
        end
      end
    end
  end

  describe 'POST /projects/user/:id' do
    let(:admin) { create(:admin) }
    let(:api_call) { post api("/projects/user/#{user.id}", admin, admin_mode: true), params: project_params }

    context 'with templates' do
      include_context 'instance template name' do
        it_behaves_like 'creates projects with templates'
      end

      include_context 'instance template ID' do
        it_behaves_like 'creates projects with templates'
      end

      include_context 'group template name' do
        it_behaves_like 'creates projects with templates'
      end

      include_context 'group template ID' do
        it_behaves_like 'creates projects with templates'
      end
    end
  end

  describe 'POST /projects' do
    let(:api_call) { post api('/projects', user), params: project_params }

    context 'with templates' do
      include_context 'instance template name' do
        it_behaves_like 'creates projects with templates'
      end

      include_context 'instance template ID' do
        it_behaves_like 'creates projects with templates'
      end

      include_context 'group template name' do
        it_behaves_like 'creates projects with templates'
      end

      include_context 'group template ID' do
        it_behaves_like 'creates projects with templates'
      end
    end

    context 'when importing with mirror attributes' do
      let(:import_url) { generate(:url) }
      let(:mirror_params) do
        {
          name: "Foo",
          mirror: true,
          import_url: import_url,
          mirror_trigger_builds: true
        }
      end

      before do
        git_response = {
          status: 200,
          body: '001e# service=git-upload-pack',
          headers: { 'Content-Type': 'application/x-git-upload-pack-advertisement' }
        }
        stub_full_request("#{import_url}/info/refs?service=git-upload-pack", method: :get).to_return(git_response)
        stub_application_setting(import_sources: ['git'])
      end

      it 'creates new project with pull mirroring set up' do
        post api('/projects', user), params: mirror_params

        expect(response).to have_gitlab_http_status(:created)
        expect(Project.find(json_response['id'])).to have_attributes(
          mirror: true,
          import_url: import_url,
          mirror_user_id: user.id,
          mirror_trigger_builds: true
        )
      end

      it 'creates project without mirror settings when repository mirroring feature is disabled' do
        stub_licensed_features(repository_mirrors: false)

        expect { post api('/projects', user), params: mirror_params }
          .to change { Project.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(Project.find(json_response['id'])).to have_attributes(
          mirror: false,
          import_url: import_url,
          mirror_user_id: nil,
          mirror_trigger_builds: false
        )
      end

      context 'when pull mirroring is not available' do
        before do
          stub_ee_application_setting(mirror_available: false)
        end

        it 'ignores the mirroring options' do
          post api('/projects', user), params: mirror_params

          expect(response).to have_gitlab_http_status(:created)
          expect(Project.find(json_response['id']).mirror?).to be false
        end

        it 'creates project with mirror settings' do
          admin = create(:admin)

          post api('/projects', admin, admin_mode: true), params: mirror_params

          expect(response).to have_gitlab_http_status(:created)
          expect(Project.find(json_response['id'])).to have_attributes(
            mirror: true,
            import_url: import_url,
            mirror_user_id: admin.id,
            mirror_trigger_builds: true
          )
        end
      end
    end

    context 'with requirements_access_level' do
      let(:project_params) { { name: 'bar', requirements_access_level: 'disabled' } }

      before do
        stub_licensed_features(requirements: true)
      end

      it 'updates project with given value' do
        post api('/projects', user), params: project_params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['requirements_access_level']).to eq(project_params[:requirements_access_level])
      end
    end
  end

  describe 'GET projects/:id/audit_events' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public, namespace: user.namespace) }

    let(:path) { "/projects/#{project.id}/audit_events" }

    it_behaves_like 'inaccessable by reporter role and lower'

    context 'when authenticated, as a member' do
      let_it_be(:developer) { create(:user) }

      before do
        stub_licensed_features(audit_events: true)
        project.add_developer(developer)
      end

      it 'returns only events authored by current user' do
        project_audit_event_1 = create(:project_audit_event, entity_id: project.id, author_id: developer.id)
        create(:project_audit_event, entity_id: project.id, author_id: 666)

        get api(path, developer)

        expect_response_contain_exactly(project_audit_event_1.id)
      end
    end

    context 'when authenticated, as a project owner' do
      before do
        project.add_maintainer(user)
      end

      context 'audit events feature is not available' do
        before do
          stub_licensed_features(audit_events: false)
        end

        it_behaves_like '403 response' do
          let(:request) { get api(path, user) }
        end
      end

      context 'audit events feature is available' do
        let_it_be(:project_audit_event_1) { create(:project_audit_event, created_at: Date.new(2000, 1, 10), entity_id: project.id) }
        let_it_be(:project_audit_event_2) { create(:project_audit_event, created_at: Date.new(2000, 1, 15), entity_id: project.id) }
        let_it_be(:project_audit_event_3) { create(:project_audit_event, created_at: Date.new(2000, 1, 20), entity_id: project.id) }

        before do
          stub_licensed_features(audit_events: true)
        end

        it 'returns 200 response' do
          get api(path, user)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'includes the correct pagination headers' do
          audit_events_counts = 3

          get api(path, user)

          expect(response).to include_pagination_headers
          expect(response.headers['X-Total']).to eq(audit_events_counts.to_s)
          expect(response.headers['X-Page']).to eq('1')
        end

        it 'does not include audit events of a different project' do
          project = create(:project)
          audit_event = create(:project_audit_event, created_at: Date.new(2000, 1, 20), entity_id: project.id)

          get api(path, user)

          audit_event_ids = json_response.map { |audit_event| audit_event['id'] }

          expect(audit_event_ids).not_to include(audit_event.id)
        end

        context 'parameters' do
          it_behaves_like 'supports keyset pagination' do
            let_it_be(:admin) { create(:admin) }
            let!(:audit_event_1) { create(:project_audit_event, entity_id: project.id) }
            let!(:audit_event_2) { create(:project_audit_event, entity_id: project.id) }
            let(:url) { "/projects/#{project.id}/audit_events" }
          end

          context 'created_before parameter' do
            it "returns audit events created before the given parameter" do
              created_before = '2000-01-20T00:00:00.060Z'

              get api(path, user), params: { created_before: created_before }

              expect(json_response.size).to eq 3
              expect(json_response.first["id"]).to eq(project_audit_event_3.id)
              expect(json_response.last["id"]).to eq(project_audit_event_1.id)
            end
          end

          context 'created_after parameter' do
            it "returns audit events created after the given parameter" do
              created_after = '2000-01-12T00:00:00.060Z'

              get api(path, user), params: { created_after: created_after }

              expect(json_response.size).to eq 2
              expect(json_response.first["id"]).to eq(project_audit_event_3.id)
              expect(json_response.last["id"]).to eq(project_audit_event_2.id)
            end
          end
        end

        context 'response schema' do
          it 'matches the response schema' do
            get api(path, user)

            expect(response).to match_response_schema('public_api/v4/audit_events', dir: 'ee')
          end
        end

        context 'Snowplow event tracking' do
          it_behaves_like 'Snowplow event tracking with RedisHLL context' do
            subject(:api_request) { get api(path, user) }

            let(:category) { 'EE::API::Projects' }
            let(:action) { 'project_audit_event_request' }
            let(:namespace) { project.namespace }
            let(:context) { [::Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: 'a_compliance_audit_events_api').to_context] }
          end
        end
      end
    end
  end

  describe 'GET projects/:id/audit_events/:audit_event_id' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public, namespace: user.namespace) }
    let(:path) { "/projects/#{project.id}/audit_events/#{project_audit_event.id}" }

    let_it_be(:project_audit_event) { create(:project_audit_event, created_at: Date.new(2000, 1, 10), entity_id: project.id) }

    it_behaves_like 'inaccessable by reporter role and lower'

    context 'when authenticated, as a guest' do
      let_it_be(:guest) { create(:user) }

      before do
        stub_licensed_features(audit_events: true)
        project.add_guest(guest)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(path, guest) }
      end
    end

    context 'when authenticated, as a member' do
      let_it_be(:developer) { create(:user) }

      before do
        stub_licensed_features(audit_events: true)
        project.add_developer(developer)
      end

      it 'returns 200 response' do
        audit_event = create(:project_audit_event, entity_id: project.id, author_id: developer.id)
        path = "/projects/#{project.id}/audit_events/#{audit_event.id}"

        get api(path, developer)

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'existing audit event of a different user' do
        let_it_be(:audit_event) { create(:project_audit_event, entity_id: project.id, author_id: another_user.id) }

        let(:path) { "/projects/#{project.id}/audit_events/#{audit_event.id}" }

        it_behaves_like '404 response' do
          let(:request) { get api(path, developer) }
        end
      end
    end

    context 'when authenticated, as a project owner' do
      context 'audit events feature is not available' do
        before do
          stub_licensed_features(audit_events: false)
        end

        it_behaves_like '403 response' do
          let(:request) { get api(path, user) }
        end
      end

      context 'audit events feature is available' do
        before do
          stub_licensed_features(audit_events: true)
        end

        context 'existent audit event' do
          it 'returns 200 response' do
            get api(path, user)

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'response schema' do
            it 'matches the response schema' do
              get api(path, user)

              expect(response).to match_response_schema('public_api/v4/audit_event', dir: 'ee')
            end
          end

          context 'invalid audit_event_id' do
            let(:path) { "/projects/#{project.id}/audit_events/an-invalid-id" }

            it_behaves_like '400 response' do
              let(:request) { get api(path, user) }
            end
          end

          context 'non existent audit event' do
            context 'non existent audit event of a project' do
              let(:path) { "/projects/#{project.id}/audit_events/666777" }

              it_behaves_like '404 response' do
                let(:request) { get api(path, user) }
              end
            end

            context 'existing audit event of a different project' do
              let(:new_project) { create(:project) }
              let(:audit_event) { create(:project_audit_event, created_at: Date.new(2000, 1, 10), entity_id: new_project.id) }

              let(:path) { "/projects/#{project.id}/audit_events/#{audit_event.id}" }

              it_behaves_like '404 response' do
                let(:request) { get api(path, user) }
              end
            end
          end
        end
      end
    end
  end

  describe 'PUT /projects/:id' do
    let(:project) { create(:project, namespace: user.namespace) }
    let(:project_params) { {} }

    subject { put api("/projects/#{project.id}", user), params: project_params }

    context 'issuable default templates feature is available' do
      before do
        stub_licensed_features(issuable_default_templates: true)
      end

      context 'when updating issues_template' do
        let(:project_params) { { issues_template: '## New Issue Template' } }

        it 'updates the content' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['issues_template']).to eq(project_params[:issues_template])
        end
      end

      context 'when updating merge_requests_template' do
        let(:project_params) { { merge_requests_template: '## New Merge Request Template' } }

        it 'updates the content' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['merge_requests_template']).to eq(project_params[:merge_requests_template])
        end
      end

      context 'when updating requirements_access_level' do
        let(:project_params) { { requirements_access_level: 'disabled' } }

        before do
          stub_licensed_features(requirements: true)
        end

        it 'updates project with given value' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['requirements_access_level']).to eq(project_params[:requirements_access_level])
        end
      end
    end

    context 'issuable default templates feature not available' do
      before do
        stub_licensed_features(issuable_default_templates: false)
      end

      context 'when updating issues_template' do
        let(:project_params) { { issues_template: '## New Issue Template' } }

        it 'does not update the content' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).not_to have_key 'issues_template'
        end
      end

      context 'when updating merge_requests_template' do
        let(:project_params) { { merge_requests_template: '## New Merge Request Template' } }

        it 'does not update the content' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).not_to have_key 'merge_requests_template'
        end
      end
    end

    context 'merge pipelines feature is available' do
      before do
        stub_licensed_features(merge_pipelines: true)
      end

      let(:project_params) { { merge_pipelines_enabled: true } }

      it 'updates the content' do
        expect { subject }.to change { project.reload.merge_pipelines_enabled }

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.merge_pipelines_enabled).to eq(project_params[:merge_pipelines_enabled])
        expect(json_response['merge_pipelines_enabled']).to eq(project_params[:merge_pipelines_enabled])
      end

      context 'when user does not have permission' do
        let(:developer_user) { create(:user) }

        before do
          project.add_developer(developer_user)
        end

        it 'does not update the content' do
          expect do
            put api("/projects/#{project.id}", developer_user), params: project_params
          end.not_to change { project.reload.merge_pipelines_enabled }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'merge pipelines feature feature not available' do
      before do
        stub_licensed_features(merge_pipelines: false)
      end

      let(:project_params) { { merge_pipelines_enabled: true } }

      it 'does not update the content' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'merge_pipelines_enabled'
      end
    end

    context 'when external_status_checks is available' do
      before do
        stub_licensed_features(external_status_checks: true)
      end

      let(:project_params) { { only_allow_merge_if_all_status_checks_passed: true } }

      it 'updates the content' do
        expect { subject }.to change { project.reload.only_allow_merge_if_all_status_checks_passed }.from(false).to(true)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['only_allow_merge_if_all_status_checks_passed']).to eq(project_params[:only_allow_merge_if_all_status_checks_passed])
      end

      context 'when user does not have permission' do
        let(:developer_user) { create(:user) }

        before do
          project.add_developer(developer_user)
        end

        it 'does not update the content' do
          expect do
            put api("/projects/#{project.id}", developer_user), params: project_params
          end.not_to change { project.reload.only_allow_merge_if_all_status_checks_passed }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when approvals_before_merge is nil' do
      let(:project_params) { { approvals_before_merge: nil } }

      it_behaves_like '400 response' do
        let(:request) { subject }
      end
    end

    context 'when external_status_checks not available' do
      before do
        stub_licensed_features(external_status_checks: false)
      end

      let(:project_params) { { only_allow_merge_if_all_status_checks_passed: true } }

      it 'does not update the content' do
        expect { subject }.to not_change { project.reload.only_allow_merge_if_all_status_checks_passed }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'only_allow_merge_if_all_status_checks_passed'
      end
    end

    context 'merge trains feature is available' do
      before do
        stub_licensed_features(merge_pipelines: true, merge_trains: true)
        project.update!(merge_pipelines_enabled: true, merge_trains_enabled: false)
        stub_feature_flags(disable_merge_trains: false)
      end

      let(:project_params) { { merge_trains_enabled: true } }

      it 'updates the content' do
        expect { subject }.to change { project.reload.merge_trains_enabled }

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.merge_trains_enabled).to eq(project_params[:merge_trains_enabled])
        expect(json_response['merge_trains_enabled']).to eq(project_params[:merge_trains_enabled])
      end

      context 'when user does not have permission' do
        let(:developer_user) { create(:user) }

        before do
          project.add_developer(developer_user)
        end

        it 'does not update the content' do
          expect do
            put api("/projects/#{project.id}", developer_user), params: project_params
          end.not_to change { project.reload.merge_trains_enabled }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'merge trains feature feature not available' do
      before do
        stub_licensed_features(merge_trains: false)
      end

      let(:project_params) { { merge_trains_enabled: true } }

      it 'does not update the content' do
        expect { subject }.not_to change { project.merge_trains_enabled }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'merge_trains_enabled'
      end
    end

    context 'when updating external classification' do
      before do
        enable_external_authorization_service_check
        stub_licensed_features(external_authorization_service_api_management: true)
      end

      let(:project_params) { { external_authorization_classification_label: 'new label' } }

      it 'updates the classification label' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.reload.external_authorization_classification_label).to eq('new label')
      end
    end

    context 'when updating mirror related attributes' do
      let(:import_url) { generate(:url) }
      let(:project_params) do
        {
          mirror: true,
          import_url: import_url,
          mirror_trigger_builds: true,
          only_mirror_protected_branches: true,
          mirror_overwrites_diverged_branches: true
        }
      end

      let(:git_response) do
        {
          status: 200,
          body: '001e# service=git-upload-pack',
          headers: { 'Content-Type': 'application/x-git-upload-pack-advertisement' }
        }
      end

      before do
        endpoint_url = "#{import_url}/info/refs?service=git-upload-pack"
        stub_full_request(endpoint_url, method: :get).to_return(git_response)
      end

      context 'when pull mirroring is not available' do
        before do
          stub_ee_application_setting(mirror_available: false)
        end

        it 'does not update mirror related attributes' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(project.reload.mirror).to be false
        end

        it 'updates mirror related attributes when user is admin' do
          admin = create(:admin)
          unrelated_user = create(:user)

          project_params[:mirror_user_id] = unrelated_user.id
          project.add_maintainer(admin)

          expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

          put(api("/projects/#{project.id}", admin, admin_mode: true), params: project_params)

          expect(response).to have_gitlab_http_status(:ok)
          expect(project.reload).to have_attributes(
            mirror: true,
            import_url: import_url,
            mirror_user_id: unrelated_user.id,
            mirror_trigger_builds: true,
            only_mirror_protected_branches: true,
            mirror_overwrites_diverged_branches: true
          )
        end
      end

      context 'when import_url is not a valid git endpoint' do
        let(:git_response) do
          {
            status: 301,
            body: '',
            headers: nil
          }
        end

        it 'disallows creating a project with an import_url that is not reachable' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq("#{import_url} is not a valid HTTP Git repository")
        end
      end

      it 'updates mirror related attributes' do
        expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.reload).to have_attributes(
          mirror: true,
          import_url: import_url,
          mirror_user_id: user.id,
          mirror_trigger_builds: true,
          only_mirror_protected_branches: true,
          mirror_overwrites_diverged_branches: true
        )
      end

      it 'updates project without mirror attributes when the project is unable to set up repository mirroring' do
        stub_licensed_features(repository_mirrors: false)

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.reload.mirror).to be false
      end

      it 'renders an API error when mirror user is invalid' do
        invalid_mirror_user = create(:user)
        project.add_developer(invalid_mirror_user)
        project_params[:mirror_user_id] = invalid_mirror_user.id

        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response["message"]["mirror_user_id"].first).to eq("is invalid")
      end

      it 'returns 403 when the user does not have access to mirror settings' do
        developer = create(:user)
        project.add_developer(developer)

        put(api("/projects/#{project.id}", developer), params: project_params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'with mirror_branch_regex and only_mirror_protected_branches' do
        let(:project_params) do
          {
            mirror: true,
            import_url: import_url,
            only_mirror_protected_branches: false,
            mirror_branch_regex: 'text'
          }
        end

        it 'fails' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with only_mirror_protected_branches' do
        context 'when enabling only_mirror_protected_branches' do
          let(:project_params) do
            {
              mirror: true,
              import_url: import_url,
              only_mirror_protected_branches: true
            }
          end

          before do
            project.update!(mirror_branch_regex: 'text')
          end

          it 'removes mirror_branch_regex' do
            expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.reload).to have_attributes(
              only_mirror_protected_branches: true,
              mirror_branch_regex: nil
            )
          end
        end

        context 'when disabling only_mirror_protected_branches' do
          let(:project_params) do
            {
              mirror: true,
              import_url: import_url,
              only_mirror_protected_branches: false
            }
          end

          before do
            project.update!(mirror_branch_regex: 'text')
          end

          it 'keeps mirror_branch_regex' do
            expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.reload).to have_attributes(
              only_mirror_protected_branches: false,
              mirror_branch_regex: 'text'
            )
          end
        end
      end

      context 'when removing mirror_branch_regex' do
        let(:project_params) do
          { mirror: true,
            import_url: import_url,
            mirror_branch_regex: nil }
        end

        context 'with mirror_branch_regex present' do
          before do
            project.update!(mirror_branch_regex: 'text')
          end

          it 'removes mirror_branch_regex' do
            expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.reload.mirror_branch_regex).to be_nil
          end
        end

        context 'with mirror_branch_regex nil and only_mirror_protected_branches is truthy' do
          before do
            project.update!(mirror_branch_regex: nil, only_mirror_protected_branches: true)
          end

          it 'does not change only_mirror_protected_branches value' do
            expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.reload.mirror_branch_regex).to be_nil
            expect(project.reload.only_mirror_protected_branches).to be_truthy
          end
        end

        context 'with mirror_branch_regex nil and only_mirror_protected_branches is false' do
          before do
            project.update!(mirror_branch_regex: nil, only_mirror_protected_branches: false)
          end

          it 'does not change only_mirror_protected_branches value' do
            expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.reload.mirror_branch_regex).to be_nil
            expect(project.reload.only_mirror_protected_branches).to be_falsey
          end
        end
      end

      context 'with mirror_branch_regex' do
        let(:project_params) do
          { mirror: true,
            import_url: import_url,
            mirror_branch_regex: 'text' }
        end

        before do
          project.update!(only_mirror_protected_branches: true)
        end

        it 'succeeds' do
          expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(project.reload).to have_attributes(
            only_mirror_protected_branches: false,
            mirror_branch_regex: 'text'
          )
        end

        it 'does nothing when feature flag is disabled' do
          stub_feature_flags(mirror_only_branches_match_regex: false)
          expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!).once

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(project.reload).to have_attributes(
            only_mirror_protected_branches: true,
            mirror_branch_regex: nil
          )
        end
      end
    end

    describe 'updating approvals_before_merge attribute' do
      context 'when authenticated as project owner' do
        let(:project_params) { { approvals_before_merge: 3 } }

        it 'updates approvals_before_merge' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['approvals_before_merge']).to eq(3)
        end
      end
    end

    context 'when protected_environments is available' do
      before do
        stub_licensed_features(protected_environments: true)
      end

      let(:project_params) { { allow_pipeline_trigger_approve_deployment: true } }

      it 'updates the content' do
        expect { subject }.to change { project.reload.allow_pipeline_trigger_approve_deployment }.from(false).to(true)
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['allow_pipeline_trigger_approve_deployment']).to eq(project_params[:allow_pipeline_trigger_approve_deployment])
      end
    end

    context 'when protected_environments not available' do
      before do
        stub_licensed_features(protected_environments: false)
      end

      let(:project_params) { { allow_pipeline_trigger_approve_deployment: true } }

      it 'does not update the content' do
        expect { subject }.to not_change { project.reload.allow_pipeline_trigger_approve_deployment }
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).not_to have_key 'allow_pipeline_trigger_approve_deployment'
      end
    end
  end

  describe 'POST /projects/:id/restore' do
    context 'feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it 'restores project' do
        project.update!(archived: true, marked_for_deletion_at: 1.day.ago, deleting_user: user)

        post api("/projects/#{project.id}/restore", user)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['archived']).to be_falsey
        expect(json_response['marked_for_deletion_at']).to be_falsey
        expect(json_response['marked_for_deletion_on']).to be_falsey
      end

      it 'returns error if project is already being deleted' do
        message = 'Error'
        expect(::Projects::RestoreService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: message })

        post api("/projects/#{project.id}/restore", user)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response["message"]).to eq(message)
      end
    end

    context 'feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it 'returns error' do
        post api("/projects/#{project.id}/restore", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }
    let(:params) { {} }

    before do
      group.add_member(user, Gitlab::Access::OWNER)
    end

    shared_examples 'deletes project immediately' do
      it :aggregate_failures do
        expect { delete api("/projects/#{project.id}", user), params: params }
          .to change { ProjectDestroyWorker.jobs.size }.by(1)
        expect(response).to have_gitlab_http_status(:accepted)
      end
    end

    shared_examples 'immediately delete project error' do
      it :aggregate_failures do
        expect { delete api("/projects/#{project.id}", user), params: params }
          .not_to change { ProjectDestroyWorker.jobs.size }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(Gitlab::Json.parse(response.body)['message']).to eq(error_message)
      end
    end

    shared_examples 'marks project for deletion' do
      it :aggregate_failures do
        delete api("/projects/#{project.id}", user)

        expect(response).to have_gitlab_http_status(:accepted)
        expect(project.reload.marked_for_deletion?).to be_truthy
      end
    end

    context 'when feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      context 'delayed project deletion is enabled for group' do
        let(:group) { create(:group) }

        before do
          group.namespace_settings.update!(delayed_project_removal: true)
        end

        it_behaves_like 'marks project for deletion'

        context 'when permanently_remove param is true' do
          before do
            params.merge!(permanently_remove: true)
          end

          context 'when project is already marked for deletion' do
            before do
              project.update!(archived: true, marked_for_deletion_at: 1.day.ago, deleting_user: user)
            end

            context 'with correct project full path' do
              before do
                params.merge!(full_path: project.full_path)
              end

              it_behaves_like 'deletes project immediately'
            end

            context 'with incorrect project full path' do
              let(:error_message) { '`full_path` is incorrect. You must enter the complete path for the project.' }

              before do
                params.merge!(full_path: "#{project.full_path}-wrong-path")
              end

              it_behaves_like 'immediately delete project error'
            end
          end

          context 'when project is not marked for deletion' do
            let(:error_message) { 'Project must be marked for deletion first.' }

            it_behaves_like 'immediately delete project error'
          end
        end

        it 'returns error if project cannot be marked for deletion' do
          message = 'Error'
          expect(::Projects::MarkForDeletionService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: message })

          delete api("/projects/#{project.id}", user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response["message"]).to eq(message)
        end

        context 'when delayed project deletion is disabled on the application' do
          before do
            stub_application_setting(lock_delayed_project_removal: true, delayed_project_removal: false)
          end

          context 'when `always_perform_delayed_deletion` is disabled' do
            before do
              stub_feature_flags(always_perform_delayed_deletion: false)
            end

            it_behaves_like 'deletes project immediately'
          end

          context 'when `always_perform_delayed_deletion` is enabled' do
            it_behaves_like 'marks project for deletion'
          end
        end

        context 'when deletion adjourned period is 0' do
          before do
            stub_application_setting(deletion_adjourned_period: 0)
          end

          it_behaves_like 'deletes project immediately'
        end
      end

      context 'delayed project deletion is disabled for group' do
        context 'when `always_perform_delayed_deletion` is disabled' do
          before do
            stub_feature_flags(always_perform_delayed_deletion: false)
          end

          it_behaves_like 'deletes project immediately'
        end

        context 'when `always_perform_delayed_deletion` is enabled' do
          it_behaves_like 'marks project for deletion'
        end
      end

      context 'for projects in user namespace' do
        let(:project) { create(:project, namespace: user.namespace) }

        it_behaves_like 'deletes project immediately'
      end
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it_behaves_like 'deletes project immediately'
    end
  end

  describe 'POST /projects/:id/fork' do
    subject(:fork_call) { post api("/projects/#{group_project.id}/fork", user), params: { namespace: target_namespace.id } }

    let!(:target_namespace) do
      create(:group).tap { |g| g.add_owner(user) }
    end

    let!(:group_project) { create(:project, namespace: group) }
    let(:group) { create(:group) }

    before do
      group.add_reporter(user)
    end

    context 'when project namespace has prohibit_outer_forks enabled' do
      let(:group) do
        create(:saml_provider, :enforced_group_managed_accounts, prohibited_outer_forks: true).group
      end

      let(:user) do
        create(:user, managing_group: group).tap do |u|
          create(:group_saml_identity, user: u, saml_provider: group.saml_provider)
        end
      end

      before do
        stub_licensed_features(group_saml: true, group_forking_protection: true)
      end

      context 'and target namespace is outer' do
        it 'renders 404' do
          expect { fork_call }.not_to change { ::Project.count }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq "404 Target Namespace Not Found"
        end
      end

      context 'and target namespace is inner to project namespace' do
        let!(:target_namespace) { create(:group, parent: group) }

        it 'forks the project' do
          target_namespace.add_owner(user)

          expect { fork_call }.to change { ::Project.count }.by(1)
        end
      end
    end
  end

  describe 'POST /projects/:id/import_project_members/:project_id' do
    let_it_be(:project) { create(:project) }
    let_it_be(:target_project) { create(:project, group: create(:group)) }

    before_all do
      project.add_maintainer(another_user)
      target_project.add_maintainer(another_user)
    end

    context 'when the target project has locked their membership' do
      context 'via the parent group' do
        before do
          target_project.group.update!(membership_lock: true)
        end

        it 'returns 403' do
          expect do
            post api("/projects/#{target_project.id}/import_project_members/#{project.id}", another_user)
          end.not_to change { target_project.members.count }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Import failed')
        end
      end

      context 'via LDAP' do
        before do
          stub_application_setting(lock_memberships_to_ldap: true)
        end

        it 'returns 403' do
          expect do
            post api("/projects/#{target_project.id}/import_project_members/#{project.id}", another_user)
          end.not_to change { target_project.members.count }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Import failed')
        end
      end
    end
  end
end
