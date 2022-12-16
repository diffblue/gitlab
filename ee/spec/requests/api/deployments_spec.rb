# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Deployments, feature_category: :continuous_delivery do
  let_it_be_with_refind(:organization) { create(:group) }
  let_it_be_with_refind(:project) { create(:project, :repository, group: organization) }

  let(:user) { create(:user) }
  let!(:environment) { create(:environment, project: project) }

  before do
    stub_licensed_features(protected_environments: true)
  end

  shared_context 'group-level protected environments with multiple approval rules' do
    let!(:security_group) { create(:group, name: 'security-group', parent: organization) }
    let!(:security_user) { create(:user) }

    before do
      security_group.add_developer(security_user)
      organization.add_reporter(security_user)
    end

    let!(:group_protected_environment) do
      create(:protected_environment, :group_level, group: organization, name: environment.tier)
    end

    let!(:approval_rule) do
      create(:protected_environment_approval_rule,
             group: security_group, protected_environment: group_protected_environment, required_approvals: 2)
    end
  end

  describe 'GET /projects/:id/deployments/:id' do
    let(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }

    before do
      create(:deployment_approval, :approved, deployment: deployment)
      project.add_developer(user)
    end

    it 'matches the response schema' do
      get api("/projects/#{project.id}/deployments/#{deployment.id}", user)

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to match_response_schema('public_api/v4/deployment_extended', dir: 'ee')
    end

    context 'with multiple approval rules' do
      include_context 'group-level protected environments with multiple approval rules'

      let!(:deployment_approval) do
        create(:deployment_approval, :approved,
               user: security_user, approval_rule: approval_rule, deployment: deployment)
      end

      it 'has approval summary' do
        get api("/projects/#{project.id}/deployments/#{deployment.id}", user)

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['approval_summary']['rules'].count).to eq(1)
        expect(json_response['approval_summary']['rules'].first['required_approvals']).to eq(2)
        expect(json_response['approval_summary']['rules'].first['deployment_approvals'].count).to eq(1)
        expect(json_response['approval_summary']['rules'].first['deployment_approvals'].first["user"]["id"])
          .to eq(security_user.id)
      end
    end
  end

  describe 'POST /projects/:id/deployments' do
    it 'matches the response schema' do
      project.add_developer(user)

      post(
        api("/projects/#{project.id}/deployments", user),
        params: {
          environment: environment.name,
          sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
          ref: 'master',
          tag: false,
          status: 'success'
        }
      )

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to match_response_schema('public_api/v4/deployment_extended', dir: 'ee')
    end

    context 'when deploying to a protected environment that requires maintainer access' do
      before do
        create(
          :protected_environment,
          :maintainers_can_deploy,
          project: environment.project,
          name: environment.name
        )
      end

      it 'returns a 403 when the user is a developer' do
        project.add_developer(user)

        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: environment.name,
            sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'creates the deployment when the user is a maintainer' do
        project.add_maintainer(user)

        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: environment.name,
            sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'when deploying to a protected environment that requires developer access' do
      before do
        create(
          :protected_environment,
          :developers_can_deploy,
          project: environment.project,
          name: environment.name
        )
      end

      it 'returns a 403 when the user is a guest' do
        project.add_guest(user)

        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: environment.name,
            sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'creates the deployment when the user is a developer' do
        project.add_developer(user)

        post(
          api("/projects/#{project.id}/deployments", user),
          params: {
            environment: environment.name,
            sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
            ref: 'master',
            tag: false,
            status: 'success'
          }
        )

        expect(response).to have_gitlab_http_status(:created)
      end
    end
  end

  describe 'PUT /projects/:id/deployments/:deployment_id' do
    let(:deploy) do
      create(
        :deployment,
        :running,
        project: project,
        deployable: nil,
        environment: environment
      )
    end

    it 'matches the response schema' do
      project.add_developer(user)

      put(
        api("/projects/#{project.id}/deployments/#{deploy.id}", user),
        params: { status: 'success' }
      )

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to match_response_schema('public_api/v4/deployment_extended', dir: 'ee')
    end

    context 'when updating a deployment for a protected environment that requires maintainer access' do
      before do
        create(
          :protected_environment,
          :maintainers_can_deploy,
          project: environment.project,
          name: environment.name
        )
      end

      it 'returns a 403 when the user is a developer' do
        project.add_developer(user)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'updates the deployment when the user is a maintainer' do
        project.add_maintainer(user)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when updating a deployment for a protected environment that requires developer access' do
      before do
        create(
          :protected_environment,
          :developers_can_deploy,
          project: environment.project,
          name: environment.name
        )
      end

      it 'returns a 403 when the user is a guest' do
        project.add_guest(user)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'updates the deployment when the user is a developer' do
        project.add_developer(user)

        put(
          api("/projects/#{project.id}/deployments/#{deploy.id}", user),
          params: { status: 'success' }
        )

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'DELETE /projects/:id/deployments/:deployment_id' do
    let(:commits) { environment.project.repository.commits(nil, { limit: 2 }) }
    let!(:deploy) do
      create(
        :deployment,
        :success,
        project: environment.project,
        environment: environment,
        deployable: nil,
        sha: commits[1].sha
      )
    end

    let!(:old_deploy) do
      create(
        :deployment,
        :success,
        project: environment.project,
        environment: environment,
        deployable: nil,
        sha: commits[0].sha,
        finished_at: 1.year.ago
      )
    end

    context 'with protected environment' do
      context 'with admin deploy' do
        before do
          create(
            :protected_environment,
            :admins_can_deploy,
            project: environment.project,
            name: environment.name
          )
        end

        it 'maintainer cannot delete a deployment' do
          project.add_maintainer(user)

          delete api("/projects/#{project.id}/deployments/#{deploy.id}", user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with maintainer deploy' do
        before do
          create(
            :protected_environment,
            :maintainers_can_deploy,
            project: environment.project,
            name: environment.name
          )
        end

        it 'maintainer can delete a deployment' do
          project.add_maintainer(user)

          delete api("/projects/#{project.id}/deployments/#{old_deploy.id}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end
  end

  describe 'POST /projects/:id/deployments/:deployment_id/approval' do
    shared_examples_for 'not created' do |approval_status: 'approved', response_status:, message:|
      it 'does not create an approval' do
        expect { post(api(path, user), params: { status: approval_status }) }.not_to change { Deployments::Approval.count }

        expect(response).to have_gitlab_http_status(response_status)
        expect(response.body).to include(message)
      end
    end

    let(:deployment) { create(:deployment, :blocked, project: project, environment: environment, deployable: create(:ci_build, :manual, project: project)) }
    let(:path) { "/projects/#{project.id}/deployments/#{deployment.id}/approval" }

    before do
      create(:protected_environment, :maintainers_can_deploy, project: environment.project, name: environment.name, required_approval_count: 1)
    end

    context 'when user is authorized to read project' do
      before do
        project.add_developer(user)
      end

      context 'and Protected Environments feature is available' do
        before do
          stub_licensed_features(protected_environments: true)
        end

        context 'and user is authorized to update deployment' do
          before do
            project.add_maintainer(user)
          end

          it 'creates an approval' do
            expect { post(api(path, user), params: { status: 'approved' }) }.to change { Deployments::Approval.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(response).to match_response_schema('public_api/v4/deployment_approval', dir: 'ee')
            expect(json_response['status']).to eq('approved')
            expect(json_response.dig('user', 'id')).to eq(user.id)
          end

          it 'creates a rejection' do
            expect { post(api(path, user), params: { status: 'rejected' }) }.to change { Deployments::Approval.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['status']).to eq('rejected')
          end

          it 'creates an approval with a comment' do
            expect { post(api(path, user), params: { status: 'approved', comment: 'LGTM!' }) }.to change { Deployments::Approval.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['comment']).to eq('LGTM!')
          end
        end

        context 'with multiple approval rules' do
          include_context 'group-level protected environments with multiple approval rules'

          it 'creates an approval' do
            expect { post(api(path, security_user), params: { status: 'approved' }) }
              .to change { Deployments::Approval.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['status']).to eq('approved')
          end

          it 'creates an approval when the user represents the group' do
            expect { post(api(path, security_user), params: { status: 'approved', represented_as: 'security' }) }
              .to change { Deployments::Approval.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['status']).to eq('approved')
          end

          it 'does not create an approval when the user does not represent the group' do
            expect { post(api(path, security_user), params: { status: 'approved', represented_as: 'qa' }) }
              .not_to change { Deployments::Approval.count }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to include("There are no approval rules for the given `represent_as` parameter. Use a valid User/Group/Role name instead.")
          end
        end

        context 'and user is not authorized to update deployment' do
          include_examples 'not created', response_status: :bad_request, message: "You don't have permission to approve this deployment. Contact the project or group owner for help."
        end

        context 'with an invalid status' do
          include_examples 'not created', approval_status: 'foo', response_status: :bad_request, message: 'status does not have a valid value'
        end

        context 'with a deployment that does not belong to the project' do
          let(:other_project) { create(:project, :repository) }

          let(:user) { other_project.creator }
          let(:path) { "/projects/#{other_project.id}/deployments/#{deployment.id}/approval" }

          include_examples 'not created', response_status: :not_found, message: '404 Not found'
        end

        context 'with a deployment that does not exist' do
          let(:path) { "/projects/#{project.id}/deployments/0/approval" }

          include_examples 'not created', response_status: :not_found, message: '404 Not found'
        end
      end

      context 'when Protected Environments feature is not available' do
        before do
          stub_licensed_features(protected_environments: false)
        end

        include_examples 'not created', response_status: :bad_request, message: 'This environment is not protected'
      end
    end

    context 'when user is Guest' do
      before do
        project.add_guest(user)
      end

      include_examples 'not created', response_status: :forbidden, message: '403 Forbidden'
    end

    context 'when user is not authorized to read project' do
      include_examples 'not created', response_status: :not_found, message: '404 Project Not Found'
    end
  end
end
