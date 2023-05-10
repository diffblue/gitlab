# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ManagedLicenses, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:maintainer_user) { create(:user) }
  let_it_be(:dev_user) { create(:user) }
  let_it_be(:reporter_user) { create(:user) }
  let_it_be(:software_license_policy) { create(:software_license_policy, project: project) }

  before do
    stub_licensed_features(license_scanning: true)
    project.add_maintainer(maintainer_user)
    project.add_developer(dev_user)
    project.add_reporter(reporter_user)
  end

  describe 'GET /projects/:id/managed_licenses' do
    context 'with license management not available' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      it 'returns a forbidden status' do
        get api("/projects/#{project.id}/managed_licenses", dev_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with an authorized user with proper permissions' do
      it 'returns an empty response' do
        get api("/projects/#{project.id}/managed_licenses", dev_user)

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end
    end

    context 'with authorized user without read permissions' do
      it 'returns an empty response' do
        get api("/projects/#{project.id}/managed_licenses", reporter_user)

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end
    end

    context 'with unauthorized user' do
      it 'returns an empty response' do
        get api("/projects/#{project.id}/managed_licenses")

        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end

      it 'responses with 404 Not Found for not existing project' do
        get api("/projects/0/managed_licenses")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when project is private' do
        before do
          project.update!(visibility_level: 'private')
        end

        it 'responses with 404 Not Found' do
          get api("/projects/#{project.id}/managed_licenses")

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /projects/:id/managed_licenses/:managed_license_id' do
    context 'authorized user with proper permissions' do
      it 'returns an empty response' do
        get api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", dev_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end

      it 'returns an empty response using the license name as key' do
        escaped_name = CGI.escape(software_license_policy.name)
        get api("/projects/#{project.id}/managed_licenses/#{escaped_name}", dev_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end

      it 'returns an empty response if requesting non-existing managed license' do
        get api("/projects/#{project.id}/managed_licenses/#{non_existing_record_id}", dev_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end
    end

    context 'authorized user with read permissions' do
      it 'returns an empty response' do
        get api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", reporter_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end
    end

    context 'unauthorized user' do
      it 'does not return project managed license details' do
        get api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'policy from license_finding rules' do
      let_it_be(:software_license_policy) do
        create(:software_license_policy, project: project, scan_result_policy_read: create(:scan_result_policy_read))
      end

      it 'returns an empty response' do
        get api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", dev_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
        expect(json_response).to be_empty
      end
    end
  end

  describe 'POST /projects/:id/managed_licenses' do
    context 'authorized user with proper permissions' do
      it 'creates managed license' do
        expect do
          post api("/projects/#{project.id}/managed_licenses", maintainer_user),
            params: {
              name: 'NEW_LICENSE_NAME',
              approval_status: 'allowed'
            }
        end.to not_change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'authorized user with read permissions' do
      it 'does not create managed license' do
        post api("/projects/#{project.id}/managed_licenses", dev_user),
          params: {
            name: 'NEW_LICENSE_NAME',
            approval_status: 'allowed'
          }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'authorized user without permissions' do
      it 'does not create managed license' do
        post api("/projects/#{project.id}/managed_licenses", reporter_user),
          params: {
            name: 'NEW_LICENSE_NAME',
            approval_status: 'allowed'
          }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not create managed license' do
        post api("/projects/#{project.id}/managed_licenses"),
          params: {
            name: 'NEW_LICENSE_NAME',
            approval_status: 'allowed'
          }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /projects/:id/managed_licenses/:managed_license_id' do
    context 'authorized user with proper permissions' do
      it 'responds with 400 Bad Request' do
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", maintainer_user),
          params: { approval_status: 'denied' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'responds with 400 Bad Request if requesting non-existing managed license' do
        patch api("/projects/#{project.id}/managed_licenses/#{non_existing_record_id}", maintainer_user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'authorized user with read permissions' do
      it 'does not update managed license' do
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", dev_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'authorized user without permissions' do
      it 'does not update managed license' do
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", reporter_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'unauthorized user' do
      it 'does not update managed license' do
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /projects/:id/managed_licenses/:managed_license_id' do
    context 'authorized user with proper permissions' do
      it 'responds with 400 Bad Request' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", maintainer_user)

          expect(response).to have_gitlab_http_status(:bad_request)
        end.to not_change { project.software_license_policies.count }
            .and not_change { SoftwareLicense.count }
      end
    end

    context 'authorized user with read permissions' do
      it 'does not delete managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", dev_user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end.not_to change { project.software_license_policies.count }
      end
    end

    context 'authorized user without permissions' do
      it 'does not delete managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", reporter_user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end.not_to change { project.software_license_policies.count }
      end
    end

    context 'unauthorized user' do
      it 'does not delete managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}")

          expect(response).to have_gitlab_http_status(:unauthorized)
        end.not_to change { project.software_license_policies.count }
      end
    end
  end
end
