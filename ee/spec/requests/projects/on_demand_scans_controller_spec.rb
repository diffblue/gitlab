# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OnDemandScansController,
  type: :request,
  feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:user) { create(:user) }

  shared_examples 'on-demand scans page' do
    include_context '"Security and Compliance" permissions' do
      let(:valid_request) { get path }

      before_request do
        project.add_developer(user)
        login_as(user)
      end
    end

    context 'feature available' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'user authorized' do
        before do
          project.add_developer(user)

          login_as(user)
        end

        it "can access page" do
          get path

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'user not authorized' do
        before do
          project.add_guest(user)

          login_as(user)
        end

        it "sees a 404 error" do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'feature not available' do
      before do
        project.add_developer(user)

        login_as(user)
      end

      it "sees a 404 error if the license doesn't support the feature" do
        stub_licensed_features(security_on_demand_scans: false)
        get path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #index' do
    it_behaves_like 'on-demand scans page' do
      let(:path) { project_on_demand_scans_path(project) }
    end
  end

  describe 'GET #new' do
    context 'user has auditor role' do
      let(:user) { create(:user, :auditor) }
      let(:path) { new_project_on_demand_scan_path(project) }

      before do
        project.add_developer(user)

        login_as(user)
      end

      it 'sees a 404 error' do
        get path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'on-demand scans page' do
      let(:path) { new_project_on_demand_scan_path(project) }
    end
  end

  describe 'GET #edit' do
    let_it_be(:tags) { [ActsAsTaggableOn::Tag.create!(name: 'ruby'), ActsAsTaggableOn::Tag.create!(name: 'postgres')] }
    let_it_be(:dast_profile) do
      create(:dast_profile, project: project, branch_name: project.default_branch_or_main, tags: tags)
    end

    let_it_be(:dast_profile_schedule) { create(:dast_profile_schedule, project: project, dast_profile: dast_profile) }

    let(:dast_profile_id) { dast_profile.id }
    let(:edit_path) { edit_project_on_demand_scan_path(project, id: dast_profile_id) }

    it_behaves_like 'on-demand scans page' do
      let(:path) { edit_path }
    end

    context 'feature available and user can access page' do
      before do
        stub_licensed_features(security_on_demand_scans: true)

        project.add_developer(user)

        login_as(user)
      end

      context 'dast_profile exists in the database' do
        it 'includes a serialized dast_profile in the response body' do
          get edit_path

          json_data = {
            **a_graphql_entity_for(dast_profile),
            name: dast_profile.name,
            description: dast_profile.description,
            tagList: dast_profile.tag_list,
            branch: { name: project.default_branch_or_main },
            dastSiteProfile: a_graphql_entity_for(DastSiteProfile.new(id: dast_profile.dast_site_profile_id)),
            dastScannerProfile: a_graphql_entity_for(DastScannerProfile.new(id: dast_profile.dast_scanner_profile_id)),
            dastProfileSchedule: {
              active: dast_profile_schedule.active,
              cadence: {
                duration: dast_profile_schedule.cadence[:duration],
                unit: dast_profile_schedule.cadence[:unit]&.upcase
              },
              startsAt: dast_profile_schedule.starts_at.in_time_zone(dast_profile_schedule.timezone).iso8601,
              timezone: dast_profile_schedule.timezone
            }
          }.to_json

          on_demand_div = Nokogiri::HTML.parse(response.body).at_css('div#js-on-demand-scans-form')

          expect(on_demand_div.attributes['data-dast-scan'].value).to eq json_data
        end
      end

      context 'dast_profile does not exist in the database' do
        let(:dast_profile_id) { 0 }

        it 'sees a 404 error' do
          get edit_path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'user has auditor role' do
        let(:user) { create(:user, :auditor) }
        let_it_be(:project) { create(:project, :repository) }

        it 'sees a 404 error' do
          get edit_path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
