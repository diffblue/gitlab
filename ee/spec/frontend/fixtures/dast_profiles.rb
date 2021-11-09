# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DAST profiles (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :public) }

    # DAST site validations
    let_it_be(:dast_site_validation_pending) do
      create(
        :dast_site_validation,
        state: :pending,
        dast_site_token: create(
          :dast_site_token,
          project: project
        )
      )
    end

    let_it_be(:dast_site_validation_inprogress) do
      create(
        :dast_site_validation,
        state: :inprogress,
        dast_site_token: create(
          :dast_site_token,
          project: project
        )
      )
    end

    let_it_be(:dast_site_validation_passed) do
      create(
        :dast_site_validation,
        state: :passed,
        dast_site_token: create(
          :dast_site_token,
          project: project
        )
      )
    end

    let_it_be(:dast_site_validation_failed) do
      create(
        :dast_site_validation,
        state: :failed,
        dast_site_token: create(
          :dast_site_token,
          project: project
        )
      )
    end

    # DAST sites
    let_it_be(:dast_site_pending) { create(:dast_site, project: project, dast_site_validation: dast_site_validation_pending) }
    let_it_be(:dast_site_inprogress) { create(:dast_site, project: project, dast_site_validation: dast_site_validation_inprogress) }
    let_it_be(:dast_site_passed) { create(:dast_site, project: project, dast_site_validation: dast_site_validation_passed) }
    let_it_be(:dast_site_failed) { create(:dast_site, project: project, dast_site_validation: dast_site_validation_failed) }
    let_it_be(:dast_site_none) { create(:dast_site, project: project, dast_site_validation: nil) }

    before do
      stub_licensed_features(security_on_demand_scans: true)
      project.add_developer(current_user)
    end

    describe 'dast_site_profiles' do
      path = 'security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql'

      context 'basic site profiles' do
        # DAST site profiles
        let_it_be(:dast_site_profiles) do
          [
            create(:dast_site_profile, project: project, dast_site: dast_site_none),
            create(:dast_site_profile, project: project, dast_site: dast_site_failed),
            create(:dast_site_profile, project: project, dast_site: dast_site_passed),
            create(:dast_site_profile, project: project, dast_site: dast_site_inprogress),
            create(:dast_site_profile, project: project, dast_site: dast_site_pending)
          ]
        end

        it "graphql/#{path}.basic.json" do
          query = get_graphql_query_as_string(path, ee: true)

          post_graphql(query, current_user: current_user, variables: {
            fullPath: project.full_path,
            first: 20
          })

          expect_graphql_errors_to_be_empty
          expect(graphql_data_at(:project, :siteProfiles, :edges)).to have_attributes(size: 5)
        end
      end
    end
  end
end
