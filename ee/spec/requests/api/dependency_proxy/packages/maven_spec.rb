# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DependencyProxy::Packages::Maven, :aggregate_failures, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

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
        let_it_be(:package) { create(:maven_package, project: project) }
        let(:package_file) { package.package_files.find { |f| f.file_name.end_with?('.pom') } }
        let(:path) { package.maven_metadatum.path }
        let(:file_name) { package_file.file_name }

        before do
          allow_next_instance_of(::DependencyProxy::Packages::Maven::VerifyPackageFileEtagService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success)
          end
        end

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
            true  | :custom_header | :ok
            false | :custom_header | :unauthorized
            true  | :basic_auth    | :ok
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
            true  | :custom_header | :ok
            false | :custom_header | :unauthorized
            true  | :basic_auth    | :ok
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

      shared_examples 'a user pulling files' do
        shared_examples 'returning a workhorse sendurl response' do
          it 'returns a workhorse sendurl response' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('send-url:')
            expect(response.headers['Content-Type']).to eq('application/octet-stream')
            expect(response.headers['Content-Length'].to_i).to eq(0)
            expect(response.body).to eq('')

            send_data_type, send_data = workhorse_send_data
            url, allow_redirect = send_data.values_at('URL', 'AllowRedirects')

            expect(send_data_type).to eq('send-url')
            expect(url).to be_present
            expect(allow_redirect).to be_truthy
          end
        end

        shared_examples 'returning a workhorse senddependency response' do
          it 'returns a workhorse senddependency response' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('send-dependency:')
            expect(response.headers['Content-Type']).to eq('application/octet-stream')
            expect(response.headers['Content-Length'].to_i).to eq(0)
            expect(response.body).to eq('')

            send_data_type, send_data = workhorse_send_data
            headers, url, upload_config = send_data.values_at('Headers', 'Url', 'UploadConfig')

            expect(send_data_type).to eq('send-dependency')
            expect(url).to be_present
            expect(headers).to be_blank
            expect(upload_config['Method']).to eq('PUT')
            expect(upload_config['Url']).to be_present
          end
        end

        shared_examples 'pulling existing files' do |can_destroy_package_files: false|
          let_it_be(:package) { create(:maven_package, project: project) }

          let(:package_file) { package.package_files.find { |f| f.file_name.end_with?('.pom') } }
          let(:path) { package.maven_metadatum.path }

          context 'when pulling a pom file' do
            let(:file_name) { package_file.file_name }

            wrong_etag_shared_example = if can_destroy_package_files
                                          'returning a workhorse senddependency response'
                                        else
                                          'returning a workhorse sendurl response'
                                        end

            where(:etag_service_response, :expected_status, :shared_example) do
              ServiceResponse.success                                          | :ok | nil
              ServiceResponse.error(message: '', reason: :response_error_code) | :ok | nil
              ServiceResponse.error(message: '', reason: :wrong_etag)          | nil | wrong_etag_shared_example
            end

            with_them do
              before do
                allow_next_instance_of(::DependencyProxy::Packages::Maven::VerifyPackageFileEtagService) do |service|
                  allow(service).to receive(:execute).and_return(etag_service_response)
                end
              end

              it_behaves_like 'returning response status', params[:expected_status] if params[:expected_status]
              it_behaves_like params[:shared_example] if params[:shared_example]
            end
          end

          [:md5, :sha1].each do |format|
            context "when pulling a #{format} file" do
              let(:file_name) { "#{package_file.file_name}.#{format}" }

              it 'returns it' do
                subject

                expect(response).to have_gitlab_http_status(:successful)
                expect(response.body).to eq(package_file["file_#{format}"])
              end
            end
          end
        end

        shared_examples 'pulling non existing files' do |can_write_package_files: true|
          context 'with file test.pom' do
            let(:file_name) { 'test.pom' }

            if can_write_package_files
              it_behaves_like 'returning a workhorse senddependency response'
            else
              it_behaves_like 'returning a workhorse sendurl response'
            end
          end

          context 'with file test.md5' do
            let(:file_name) { 'test.md5' }

            it_behaves_like 'returning a workhorse sendurl response'
          end

          context 'with file test.sha1' do
            let(:file_name) { 'test.sha1' }

            it_behaves_like 'returning a workhorse sendurl response'
          end
        end

        shared_context 'with custom headers' do
          let(:headers) { { 'Private-Token' => personal_access_token.token } }
        end

        shared_context 'with basic auth' do
          let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
        end

        context 'with a reporter pulling files' do
          before_all do
            project.add_reporter(user)
          end

          include_context 'with custom headers' do
            it_behaves_like 'pulling existing files'
            it_behaves_like 'pulling non existing files', can_write_package_files: false
          end

          include_context 'with basic auth' do
            it_behaves_like 'pulling existing files'
            it_behaves_like 'pulling non existing files', can_write_package_files: false
          end
        end

        context 'with a developer pulling files' do
          before_all do
            project.add_developer(user)
          end

          include_context 'with custom headers' do
            it_behaves_like 'pulling existing files'
            it_behaves_like 'pulling non existing files'
          end

          include_context 'with basic auth' do
            it_behaves_like 'pulling existing files'
            it_behaves_like 'pulling non existing files'
          end
        end

        context 'with a maintainer pulling files' do
          before_all do
            project.add_maintainer(user)
          end

          include_context 'with custom headers' do
            it_behaves_like 'pulling existing files', can_destroy_package_files: true
            it_behaves_like 'pulling non existing files'
          end

          include_context 'with basic auth' do
            it_behaves_like 'pulling existing files', can_destroy_package_files: true
            it_behaves_like 'pulling non existing files'
          end

          context 'with a ci job token' do
            context 'with custom headers' do
              let(:headers) { { 'Job-Token' => job.token } }

              it_behaves_like 'pulling existing files', can_destroy_package_files: true
              it_behaves_like 'pulling non existing files'
            end

            context 'with basic auth' do
              let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token) }

              it_behaves_like 'pulling existing files', can_destroy_package_files: true
              it_behaves_like 'pulling non existing files'
            end
          end
        end

        context 'with a deploy token' do
          context 'with custom headers' do
            let(:headers) { { 'Deploy-Token' => deploy_token.token } }

            it_behaves_like 'pulling existing files', can_destroy_package_files: true
            it_behaves_like 'pulling non existing files'
          end

          context 'with basic auth' do
            let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token) }

            it_behaves_like 'pulling existing files', can_destroy_package_files: true
            it_behaves_like 'pulling non existing files'
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
                [:anonymous,     nil,   nil,            :forbidden],
                [:guest,         true,  :custom_header, :ok],
                [:guest,         true,  :basic_auth,    :ok],
                [:guest,         false, :custom_header, :unauthorized],
                [:guest,         false, :basic_auth,    :unauthorized]
              ]
            it_behaves_like 'a user pulling files'
          end

          context 'with an internal project' do
            before do
              project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
            end

            it_behaves_like 'handling different token types',
              personal_access_token_cases: [
                [:anonymous,     nil,   nil,            :unauthorized],
                [:guest,         true,  :custom_header, :ok],
                [:guest,         true,  :basic_auth,    :ok],
                [:guest,         false, :custom_header, :unauthorized],
                [:guest,         false, :basic_auth,    :unauthorized]
              ]
            it_behaves_like 'a user pulling files'
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
                [:reporter,  true,  :custom_header, :ok],
                [:reporter,  true,  :basic_auth,    :ok],
                [:reporter,  false, :custom_header, :unauthorized],
                [:reporter,  false, :basic_auth,    :unauthorized]
              ]
            it_behaves_like 'a user pulling files'
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
