# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Dependencies, feature_category: :dependency_management do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  describe "GET /projects/:id/dependencies" do
    subject(:request) { get api("/projects/#{project.id}/dependencies", user), params: params }

    let(:params) { {} }
    let(:snowplow_standard_context_params) { { user: user, project: project, namespace: project.namespace } }

    before do
      stub_licensed_features(dependency_scanning: true, license_scanning: true, security_dashboard: true)
    end

    it_behaves_like 'a gitlab tracking event', described_class.name, 'view_dependencies'

    context 'with an authorized user with proper permissions' do
      let_it_be(:finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata) }
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }
      let_it_be(:finding_pipeline) { create(:vulnerabilities_finding_pipeline, finding: finding, pipeline: pipeline) }

      before do
        project.add_developer(user)
        request
      end

      it 'returns paginated dependencies' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/dependencies', dir: 'ee')
        expect(response).to include_pagination_headers

        expect(json_response.length).to eq(20)
      end

      it 'returns vulnerabilities info' do
        vulnerability = json_response.find { |dep| dep['name'] == 'nokogiri' }['vulnerabilities'][0]
        path = "/security/vulnerabilities/#{finding.vulnerability_id}"

        expect(vulnerability['name']).to eq('Vulnerabilities in libxml2')
        expect(vulnerability['severity']).to eq('high')
        expect(vulnerability['id']).to eq(finding.vulnerability_id)
        expect(vulnerability['url']).to end_with(path)
      end

      context 'when the license_scanning_sbom_scanner feature flag is false' do
        before_all do
          stub_feature_flags(license_scanning_sbom_scanner: false)
          create(:ee_ci_build, :success, :license_scanning, pipeline: pipeline)
        end

        it 'include license information to response' do
          license = json_response.find { |dep| dep['name'] == 'nokogiri' }['licenses'][0]

          expect(license['name']).to eq('MIT')
          expect(license['url']).to eq('http://opensource.org/licenses/mit-license')
        end
      end

      context 'when the license_scanning_sbom_scanner feature flag is true' do
        before_all do
          create(:ee_ci_build, :success, :cyclonedx, pipeline: pipeline)
          create(:pm_package_version_license, :with_all_relations, name: 'nokogiri', purl_type: 'gem',
            version: '1.8.0', license_name: 'MIT')
        end

        it 'include license information to response' do
          license = json_response.find { |dep| dep['name'] == 'nokogiri' }['licenses'][0]

          expect(license['name']).to eq('MIT')
          expect(license['url']).to eq('https://spdx.org/licenses/MIT.html')
        end
      end

      context 'with nil package_manager' do
        let(:params) { { package_manager: nil } }

        it 'returns no dependencies' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/dependencies', dir: 'ee')

          expect(json_response).to eq([])
        end
      end

      context 'with filter options' do
        let(:params) { { package_manager: 'yarn' } }

        it 'returns yarn dependencies' do
          expect(json_response.length).to eq(19)
        end

        context 'with wrong key' do
          let(:params) { { package_manager: %w(nray yarn) } }

          it 'returns error message' do
            expect(json_response['error']).to eq('package_manager does not have a valid value')
          end
        end
      end

      context 'with pagination params' do
        let(:params) { { per_page: 5, page: 5 } }

        it 'returns paginated dependencies' do
          expect(response).to match_response_schema('public_api/v4/dependencies', dir: 'ee')
          expect(response).to include_pagination_headers

          expect(json_response.length).to eq(1)
        end
      end
    end

    context 'without permissions to see vulnerabilities' do
      before do
        create(:ee_ci_pipeline, :with_dependency_list_report, project: project)
        request
      end

      it 'returns empty vulnerabilities' do
        expect(json_response.first['vulnerabilities']).to be_nil
      end
    end

    context 'without permissions to see licenses' do
      before do
        # The only way a user can access this API but not license scanning results is when the feature is disabled
        stub_licensed_features(dependency_scanning: true, license_scanning: false, security_dashboard: true)
        create(:ee_ci_pipeline, :with_dependency_list_report, project: project)
        request
      end

      it 'returns empty licenses' do
        expect(json_response.first['licenses']).to be_nil
      end
    end

    context 'with authorized user without read permissions' do
      let(:project) { create(:project, :private) }

      before do
        project.add_guest(user)
        request
      end

      it 'responds with 403 Forbidden' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with no project access' do
      let(:project) { create(:project, :private) }

      before do
        request
      end

      it 'responds with 404 Not Found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
