# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DAST profiles (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers
    include API::Helpers::GraphqlHelpers
    include RepoHelpers

    shared_examples 'dast_site_profiles.query.graphql' do |type|
      path = 'security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql'

      it "graphql/#{path}.#{type}.json" do
        query = get_graphql_query_as_string(path, ee: true)

        post_graphql(query, current_user: current_user, variables: {
          fullPath: project.full_path,
          first: 20
        })

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project, :siteProfiles, :nodes)).to have_attributes(size: dast_site_profiles.length)
      end
    end

    shared_examples 'dast_scanner_profiles.query.graphql' do |type|
      path = 'security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql'

      it "graphql/#{path}.#{type}.json" do
        query = get_graphql_query_as_string(path, ee: true)

        post_graphql(query, current_user: current_user, variables: {
          fullPath: project.full_path,
          first: 20
        })

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project, :scannerProfiles, :nodes)).to have_attributes(size: dast_scanner_profiles.length)
      end
    end

    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :public) }

    before do
      stub_licensed_features(security_on_demand_scans: true)
      project.add_developer(current_user)
    end

    describe 'dast_site_profiles' do
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
      let_it_be(:dast_site_pending) do
        create(
          :dast_site,
          project: project,
          url: 'http://pending.test',
          dast_site_validation: dast_site_validation_pending
        )
      end

      let_it_be(:dast_site_inprogress) do
        create(
          :dast_site,
          project: project,
          url: 'http://inprogress.test',
          dast_site_validation: dast_site_validation_inprogress
        )
      end

      let_it_be(:dast_site_passed) do
        create(
          :dast_site,
          project: project,
          url: 'http://passed.test',
          dast_site_validation: dast_site_validation_passed
        )
      end

      let_it_be(:dast_site_failed) do
        create(
          :dast_site,
          project: project,
          url: 'http://failed.test',
          dast_site_validation: dast_site_validation_failed
        )
      end

      let_it_be(:dast_site_none) do
        create(
          :dast_site,
          project: project,
          url: 'http://none.test',
          dast_site_validation: nil
        )
      end

      context 'basic site profiles' do
        # DAST site profiles
        let_it_be(:dast_site_profiles) do
          [
            create(
              :dast_site_profile,
              name: "Non-validated",
              auth_username: "non-validated@example.com",
              project: project,
              dast_site: dast_site_none
            ),
            create(
              :dast_site_profile,
              name: "Validation failed",
              auth_username: "validation-failed@example.com",
              project: project,
              dast_site: dast_site_failed
            ),
            create(
              :dast_site_profile,
              name: "Validation passed",
              auth_username: "validation-passed@example.com",
              project: project,
              dast_site: dast_site_passed
            ),
            create(
              :dast_site_profile,
              name: "Validation in progress",
              auth_username: "validation-in-progress@example.com",
              project: project,
              dast_site: dast_site_inprogress
            ),
            create(
              :dast_site_profile,
              name: "Validation pending",
              auth_username: "validation-pending@example.com",
              project: project,
              dast_site: dast_site_pending
            )
          ]
        end

        it_behaves_like 'dast_site_profiles.query.graphql', "basic"
      end

      context 'dast site profile with secret variables' do
        let(:response) { @site_profile.to_json }

        let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
        let_it_be(:request_headers_variable) { create(:dast_site_profile_secret_variable, :request_headers, dast_site_profile: dast_site_profile) }
        let_it_be(:password_variable) { create(:dast_site_profile_secret_variable, :password, dast_site_profile: dast_site_profile) }

        it "security_configuration/dast_profiles/dast_site_profile_with_secrets.json" do
          query = %(
            {
              project(fullPath: "#{project.full_path}") {
                dastSiteProfile(id: "#{Gitlab::GlobalId.as_global_id(dast_site_profile.id, model_name: 'DastSiteProfile')}") {
                  id
                  name: profileName
                  targetUrl
                  targetType
                  excludedUrls
                  requestHeaders
                  auth { enabled url username usernameField password passwordField submitField}
                  referencedInSecurityPolicies
                }
              }
            }
          )
          @site_profile = run_graphql!(
            query: query,
            context: { current_user: current_user },
            transform: -> (result) { result.dig('data', 'project', 'dastSiteProfile') }
          )
        end
      end
    end

    describe 'dast_scanner_profiles' do
      # DAST scanner profiles
      let_it_be(:dast_scanner_profiles) do
        [
          create(
            :dast_scanner_profile,
            name: "Active scanner",
            spider_timeout: 5,
            target_timeout: 10,
            scan_type: 'active',
            use_ajax_spider: true,
            show_debug_messages: true,
            project: project
          ),
          create(
            :dast_scanner_profile,
            name: "Passive scanner",
            spider_timeout: 5,
            target_timeout: 10,
            scan_type: 'passive',
            project: project
          )
        ]
      end

      it_behaves_like 'dast_scanner_profiles.query.graphql', "basic"
    end

    describe 'from policies' do
      let_it_be(:policies_project) { create(:project, :repository) }

      let_it_be(:security_orchestration_policy_configuration) do
        create(
          :security_orchestration_policy_configuration,
          project: project,
          security_policy_management_project: policies_project
        )
      end

      let_it_be(:dast_site_profiles) do
        [
          create(
            :dast_site_profile,
            name: "From policy",
            auth_username: "from-policy@example.com",
            project: project
          )
        ]
      end

      let_it_be(:dast_scanner_profiles) do
        [
          create(
            :dast_scanner_profile,
            name: "Active scanner",
            spider_timeout: 5,
            target_timeout: 10,
            scan_type: 'active',
            use_ajax_spider: true,
            show_debug_messages: true,
            project: project
          )
        ]
      end

      let(:policy1) do
        build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: %w[master] }], actions: [
                { scan: 'dast', site_profile: dast_site_profiles.first.name, scanner_profile: dast_scanner_profiles.first.name }
              ])
      end

      let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy1]) }

      before do
        create_file_in_repo(policies_project, 'master', 'master', Security::OrchestrationPolicyConfiguration::POLICY_PATH, policy_yaml)
      end

      context "site profiles" do
        it_behaves_like 'dast_site_profiles.query.graphql', "from_policies"
      end

      context "scanner profiles" do
        it_behaves_like 'dast_scanner_profiles.query.graphql', "from_policies"
      end
    end

    describe 'scheduled_dast_profiles' do
      path = 'on_demand_scans/graphql/scheduled_dast_profiles.query.graphql'

      let_it_be(:dast_profile) { create(:dast_profile, project: project) }

      let_it_be(:dast_profile_schedule) do
        create(:dast_profile_schedule, project: project, dast_profile: dast_profile)
      end

      it "graphql/#{path}.json" do
        query = get_graphql_query_as_string(path, ee: true)

        post_graphql(query, current_user: current_user, variables: {
          fullPath: project.full_path,
          first: 20
        })

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project, :pipelines, :nodes)).to have_attributes(size: 1)
      end
    end

    describe 'dast_site_validations' do
      context 'failed site validations' do
        path = 'security_configuration/dast_profiles/graphql/dast_failed_site_validations.query.graphql'

        let_it_be(:dast_site_validation_https) do
          create(
            :dast_site_validation,
            state: :failed,
            dast_site_token: create(
              :dast_site_token,
              url: 'https://example.com',
              project: project
            )
          )
        end

        let_it_be(:dast_site_validation_http) do
          create(
            :dast_site_validation,
            state: :failed,
            dast_site_token: create(
              :dast_site_token,
              url: 'http://example.com',
              project: project
            )
          )
        end

        it "graphql/#{path}.json" do
          query = get_graphql_query_as_string(path, ee: true)

          post_graphql(query, current_user: current_user, variables: {
            fullPath: project.full_path
          })

          expect_graphql_errors_to_be_empty
          expect(graphql_data_at(:project, :validations, :nodes)).to have_attributes(size: 2)
        end
      end
    end

    describe 'dast_profiles' do
      path = 'on_demand_scans/graphql/dast_profiles.query.graphql'

      let_it_be(:dast_profiles) do
        create_list(:dast_profile, 3, project: project)
      end

      before do
        dast_profiles.last.branch_name = SecureRandom.hex
        dast_profiles.last.save!(validate: false)
      end

      it "graphql/#{path}.json" do
        query = get_graphql_query_as_string(path, ee: true)

        post_graphql(query, current_user: current_user, variables: {
          fullPath: project.full_path,
          first: 20
        })

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project, :pipelines, :nodes)).to have_attributes(size: dast_profiles.size)
      end
    end
  end
end
