# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DependencyProxy::Packages::Maven, :aggregate_failures, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be_with_refind(:dependency_proxy_setting) do
    create(:dependency_proxy_packages_setting, :maven, project: project)
  end

  # all tokens that we're going to use
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:job) { create(:ci_build, user: user, status: :running, project: project) }

  describe 'GET /api/v4/projects/:project_id/dependency_proxy/packages/maven/*path/:file_name' do
    let(:path) { 'foo/bar/1.2.3' }
    let(:file_name) { 'foo.bar-1.2.3.pom' }
    let(:url) { "/projects/#{project.id}/dependency_proxy/packages/maven/#{path}/#{file_name}" }

    subject { get(api(url), headers: headers) }

    before do
      stub_licensed_features(dependency_proxy_for_packages: true)
      stub_config(dependency_proxy: { enabled: true }) # not enabled by default
    end

    context 'with valid parameters' do
      shared_examples 'handling different token types' do |personal_access_token_cases:|
        context 'and a personal access token' do
          where(:user_role, :valid_token, :sent_using, :expected_status) do
            personal_access_token_cases
          end

          with_them do
            let(:token) { valid_token ? personal_access_token.token : 'invalid_token' }
            let(:headers) do
              case sent_using
              when :custom_header
                { 'Private-Token' => token }
              when :basic_auth
                basic_auth_header(user.username, token)
              else
                {}
              end
            end

            before do
              project.send("add_#{user_role}", user) unless user_role == :anonymous
            end

            it_behaves_like 'returning response status', params[:expected_status]
          end
        end

        context 'and a deploy token' do
          where(:valid_token, :sent_using, :expected_status) do
            true  | :custom_header | :accepted
            false | :custom_header | :unauthorized
            true  | :basic_auth    | :accepted
            false | :basic_auth    | :unauthorized
          end

          with_them do
            let(:token) { valid_token ? deploy_token.token : 'invalid_token' }
            let(:headers) do
              case sent_using
              when :custom_header
                { 'Deploy-Token' => token }
              when :basic_auth
                basic_auth_header(deploy_token.username, token)
              else
                {}
              end
            end

            it_behaves_like 'returning response status', params[:expected_status]
          end
        end

        context 'and a ci job token' do
          where(:valid_token, :sent_using, :expected_status) do
            true  | :custom_header | :accepted
            false | :custom_header | :unauthorized
            true  | :basic_auth    | :accepted
            false | :basic_auth    | :unauthorized
          end

          with_them do
            let(:token) { valid_token ? job.token : 'invalid_token' }
            let(:headers) do
              case sent_using
              when :custom_header
                { 'Job-Token' => token }
              when :basic_auth
                basic_auth_header(::Gitlab::Auth::CI_JOB_USER, token)
              else
                {}
              end
            end

            before_all do
              project.add_developer(user)
            end

            it_behaves_like 'returning response status', params[:expected_status]
          end
        end
      end

      [true, false].each do |package_registry_public_access|
        context "with package registry public access set to #{package_registry_public_access}" do
          before do
            if package_registry_public_access
              project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
            end
          end

          context 'with a public project' do
            it_behaves_like 'handling different token types',
              personal_access_token_cases: [
                [:anonymous, nil,   nil,            :accepted],
                [:guest,     true,  :custom_header, :accepted],
                [:guest,     true,  :basic_auth,    :accepted],
                [:guest,     false, :custom_header, :unauthorized],
                [:guest,     false, :basic_auth,    :unauthorized]
              ]
          end

          context 'with an internal project' do
            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
            end

            it_behaves_like 'handling different token types',
              personal_access_token_cases: [
                [:anonymous, nil,   nil,            :unauthorized],
                [:guest,     true,  :custom_header, :accepted],
                [:guest,     true,  :basic_auth,    :accepted],
                [:guest,     false, :custom_header, :unauthorized],
                [:guest,     false, :basic_auth,    :unauthorized]
              ]
          end

          context 'with a private project' do
            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
            end

            it_behaves_like 'handling different token types',
              personal_access_token_cases: [
                [:anonymous, nil,   nil,            :unauthorized],
                [:guest,     true,  :custom_header, :forbidden],
                [:guest,     true,  :basic_auth,    :forbidden],
                [:guest,     false, :custom_header, :unauthorized],
                [:guest,     false, :basic_auth,    :unauthorized],
                [:reporter,  true,  :custom_header, :accepted],
                [:reporter,  true,  :basic_auth,    :accepted],
                [:reporter,  false, :custom_header, :unauthorized],
                [:reporter,  false, :basic_auth,    :unauthorized]
              ]
          end
        end
      end
    end

    context 'with a developer' do
      let(:headers) { { 'Private-Token' => personal_access_token.token } }

      before_all do
        project.add_developer(user)
      end

      context 'with non existing dependency proxy setting' do
        before do
          dependency_proxy_setting.destroy!
        end

        it_behaves_like 'returning response status', :not_found
      end

      context 'with disabled dependency proxy setting' do
        before do
          dependency_proxy_setting.update!(enabled: false)
        end

        it_behaves_like 'returning response status', :not_found
      end

      %i[packages dependency_proxy].each do |configuration_field|
        context "with #{configuration_field} disabled" do
          before do
            stub_config(configuration_field => { enabled: false })
          end

          it_behaves_like 'returning response status', :not_found
        end
      end

      context 'with licensed feature dependency_proxy_for_packages disabled' do
        before do
          stub_licensed_features(dependency_proxy_for_packages: false)
        end

        it_behaves_like 'returning response status', :forbidden
      end

      context 'with feature flag packages_dependency_proxy_maven disabled' do
        before do
          stub_feature_flags(packages_dependency_proxy_maven: false)
        end

        it_behaves_like 'returning response status', :not_found
      end
    end
  end
end
