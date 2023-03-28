# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Geo, :aggregate_failures, feature_category: :geo_replication do
  include GitlabShellHelpers
  include TermsHelper
  include ApiHelpers
  include WorkhorseHelpers
  include ::EE::GeoHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:primary_node) { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  let(:geo_token_header) do
    { 'X-Gitlab-Token' => secondary_node.system_hook.token }
  end

  let(:invalid_geo_auth_header) do
    { Authorization: "#{::Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE}...Test" }
  end

  let(:not_found_req_header) do
    Gitlab::Geo::TransferRequest.new(transfer.request_data.merge(file_id: 100000)).headers
  end

  before do
    stub_current_geo_node(primary_node)
  end

  shared_examples 'with terms enforced' do
    before do
      enforce_terms
    end

    it 'responds with 2xx HTTP response code' do
      request

      expect(response).to have_gitlab_http_status(:success)
    end
  end

  describe 'GET /geo/retrieve/:replicable_name/:replicable_id' do
    before do
      stub_current_geo_node(secondary_node)
    end

    let_it_be(:resource) { create(:package_file, :npm) }

    let(:replicator) { Geo::PackageFileReplicator.new(model_record_id: resource.id) }

    context 'valid requests' do
      let(:req_header) { Gitlab::Geo::Replication::BlobDownloader.new(replicator: replicator).send(:request_headers) }

      it 'returns the file' do
        get api("/geo/retrieve/#{replicator.replicable_name}/#{resource.id}"), headers: req_header

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['X-Sendfile']).to eq(resource.file.path)
      end

      context 'allowed IPs' do
        it 'responds with 401 when IP is not allowed' do
          stub_application_setting(geo_node_allowed_ips: '192.34.34.34')

          get api("/geo/retrieve/#{replicator.replicable_name}/#{resource.id}"), headers: req_header

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it 'responds with 200 when IP is allowed' do
          stub_application_setting(geo_node_allowed_ips: '127.0.0.1')

          get api("/geo/retrieve/#{replicator.replicable_name}/#{resource.id}"), headers: req_header

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'invalid requests' do
      it 'responds with 401 with invalid auth header' do
        get api("/geo/retrieve/#{replicator.replicable_name}/#{resource.id}"), headers: invalid_geo_auth_header

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'responds with 401 with mismatched params in auth headers' do
        wrong_headers = Gitlab::Geo::TransferRequest.new({ replicable_name: 'wrong', replicable_id: 1234 }).headers

        get api("/geo/retrieve/#{replicator.replicable_name}/#{resource.id}"), headers: wrong_headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'responds with 404 when resource is not found' do
        model_not_found_header = Gitlab::Geo::TransferRequest.new({ replicable_name: replicator.replicable_name, replicable_id: 1234 }).headers

        get api("/geo/retrieve/#{replicator.replicable_name}/1234"), headers: model_not_found_header

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /geo/status' do
    let(:geo_base_request) { Gitlab::Geo::BaseRequest.new(scope: ::Gitlab::Geo::API_SCOPE) }

    let(:data) do
      {
        geo_node_id: secondary_node.id,
        status_message: nil,
        db_replication_lag_seconds: 0,
        last_event_id: 2,
        last_event_date: Time.now.utc,
        cursor_last_event_id: 1,
        cursor_last_event_date: Time.now.utc,
        event_log_max_id: 555,
        repository_created_max_id: 43,
        repository_updated_max_id: 132,
        repository_deleted_max_id: 23,
        repository_renamed_max_id: 11,
        repositories_changed_max_id: 109,
        status: {
          projects_count: 10,
          repositories_synced_count: 1,
          repositories_failed_count: 2,
          wikis_synced_count: 2,
          wikis_failed_count: 3,
          lfs_objects_count: 100,
          lfs_objects_synced_count: 50,
          lfs_objects_failed_count: 12,
          lfs_objects_synced_missing_on_primary_count: 4,
          job_artifacts_count: 100,
          job_artifacts_synced_count: 50,
          job_artifacts_failed_count: 12,
          job_artifacts_synced_missing_on_primary_count: 5,
          container_repositories_count: 100,
          container_repositories_synced_count: 50,
          container_repositories_failed_count: 12,
          design_repositories_count: 100,
          design_repositories_synced_count: 50,
          design_repositories_failed_count: 12,
          container_repositories_replication_enabled: true,
          design_repositories_replication_enabled: false,
          repositories_replication_enabled: true,
          repository_verification_enabled: true
        }
      }
    end

    subject(:request) { post api('/geo/status'), params: data, headers: geo_base_request.headers }

    it 'responds with 401 with invalid auth header' do
      post api('/geo/status'), headers: invalid_geo_auth_header

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'responds with 401 when the db_key_base is wrong' do
      allow_next_instance_of(Gitlab::Geo::JwtRequestDecoder) do |instance|
        allow(instance).to receive(:decode).and_raise(Gitlab::Geo::InvalidDecryptionKeyError)
      end

      request

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    describe 'allowed IPs' do
      it 'responds with 401 when IP is not allowed' do
        stub_application_setting(geo_node_allowed_ips: '192.34.34.34')

        request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'responds with 201 when IP is allowed' do
        stub_application_setting(geo_node_allowed_ips: '127.0.0.1')

        request

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'when requesting primary node with valid auth header' do
      before do
        stub_current_geo_node(primary_node)
        allow(geo_base_request).to receive(:requesting_node) { secondary_node }
      end

      it 'updates the status and responds with 201' do
        expect { request }.to change { GeoNodeStatus.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(secondary_node.reload.status.projects_count).to eq(10)
      end

      it 'ignores invalid attributes upon update' do
        GeoNodeStatus.create!(data)
        data.merge!(
          {
            'id' => nil,
            'test' => 'something'
          }
        )

        post api('/geo/status'), params: data, headers: geo_base_request.headers

        expect(response).to have_gitlab_http_status(:created)
      end

      it_behaves_like 'with terms enforced'
    end
  end

  describe '/geo/proxy_git_ssh' do
    let(:secret_token) { Gitlab::Shell.secret_token }
    let(:primary_repo) { 'http://localhost:3001/testuser/repo.git' }
    let(:data) { { primary_repo: primary_repo, gl_id: 'key-1', gl_username: 'testuser' } }

    before do
      stub_current_geo_node(secondary_node)
    end

    describe 'POST /geo/proxy_git_ssh/info_refs_upload_pack' do
      context 'with all required params missing' do
        it 'responds with 400' do
          post api('/geo/proxy_git_ssh/info_refs_upload_pack'), params: nil, headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eql('secret_token is missing, data is missing, data[gl_id] is missing, data[primary_repo] is missing')
        end
      end

      context 'with all required params' do
        let(:git_push_ssh_proxy) { double(Gitlab::Geo::GitSSHProxy) }

        before do
          allow(Gitlab::Geo::GitSSHProxy).to receive(:new).with(data).and_return(git_push_ssh_proxy)
        end

        context 'with an invalid jwt token' do
          it 'responds with 401' do
            post(api('/geo/proxy_git_ssh/info_refs_upload_pack'), params: { secret_token: 'invalid', data: data }, headers: gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse'))

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['error']).to be_nil
          end
        end

        context 'where an exception occurs' do
          it 'responds with 500' do
            expect(git_push_ssh_proxy).to receive(:info_refs_upload_pack).and_raise('deliberate exception raised')

            post api('/geo/proxy_git_ssh/info_refs_upload_pack'), params: { secret_token: secret_token, data: data }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:internal_server_error)
            expect(json_response['message']).to include('RuntimeError (deliberate exception raised)')
            expect(json_response['result']).to be_nil
          end
        end

        context 'with a valid secret token' do
          let(:http_response) { double(Net::HTTPOK, code: 200, body: 'something here') }
          let(:api_response) { Gitlab::Geo::GitSSHProxy::APIResponse.from_http_response(http_response, primary_repo) }

          before do
            # Mocking a real Net::HTTPSuccess is very difficult as it's not
            # easy to instantiate the class due to the way it sets the body
            expect(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          end

          it 'responds with 200' do
            expect(git_push_ssh_proxy).to receive(:info_refs_upload_pack).and_return(api_response)

            post api('/geo/proxy_git_ssh/info_refs_upload_pack'), params: { secret_token: secret_token, data: data }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:ok)
            expect(Base64.decode64(json_response['result'])).to eql('something here')
          end
        end
      end
    end

    describe 'POST /geo/proxy_git_ssh/upload_pack' do
      context 'with all required params missing' do
        it 'responds with 400' do
          post api('/geo/proxy_git_ssh/upload_pack'), params: nil

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eql('secret_token is missing, data is missing, data[gl_id] is missing, data[primary_repo] is missing, output is missing')
        end
      end

      context 'with all required params' do
        let(:output) { Base64.encode64('info_refs content') }
        let(:git_push_ssh_proxy) { double(Gitlab::Geo::GitSSHProxy) }

        before do
          allow(Gitlab::Geo::GitSSHProxy).to receive(:new).with(data).and_return(git_push_ssh_proxy)
        end

        context 'with an invalid jwt token' do
          it 'responds with 401' do
            post(api('/geo/proxy_git_ssh/upload_pack'), params: { secret_token: 'invalid', data: data, output: output }, headers: gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse'))

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['error']).to be_nil
          end
        end

        context 'where an exception occurs' do
          it 'responds with 500' do
            expect(git_push_ssh_proxy).to receive(:upload_pack).and_raise('deliberate exception raised')
            post api('/geo/proxy_git_ssh/upload_pack'), params: { secret_token: secret_token, data: data, output: output }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:internal_server_error)
            expect(json_response['message']).to include('RuntimeError (deliberate exception raised)')
            expect(json_response['result']).to be_nil
          end
        end

        context 'with a valid secret token' do
          let(:http_response) { double(Net::HTTPCreated, code: 201, body: 'something here', class: Net::HTTPCreated) }
          let(:api_response) { Gitlab::Geo::GitSSHProxy::APIResponse.from_http_response(http_response, primary_repo) }

          before do
            # Mocking a real Net::HTTPSuccess is very difficult as it's not
            # easy to instantiate the class due to the way it sets the body
            expect(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          end

          it 'responds with 201' do
            expect(git_push_ssh_proxy).to receive(:upload_pack).with(output).and_return(api_response)

            post api('/geo/proxy_git_ssh/upload_pack'), params: { secret_token: secret_token, data: data, output: output }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:created)
            expect(Base64.decode64(json_response['result'])).to eql('something here')
          end
        end
      end
    end

    describe 'POST /geo/proxy_git_ssh/info_refs_receive_pack' do
      context 'with all required params missing' do
        it 'responds with 400' do
          post api('/geo/proxy_git_ssh/info_refs_receive_pack'), params: nil, headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eql('secret_token is missing, data is missing, data[gl_id] is missing, data[primary_repo] is missing')
        end
      end

      context 'with all required params' do
        let(:git_push_ssh_proxy) { double(Gitlab::Geo::GitSSHProxy) }

        before do
          allow(Gitlab::Geo::GitSSHProxy).to receive(:new).with(data).and_return(git_push_ssh_proxy)
        end

        context 'with an invalid jwt token issuer' do
          it 'responds with 401' do
            post(api('/geo/proxy_git_ssh/info_refs_receive_pack'), params: { secret_token: '', data: data }, headers: gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse'))

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['error']).to be_nil
          end
        end

        context 'with a jwt token encoded by a different secret_token' do
          it 'responds with 401' do
            post(api('/geo/proxy_git_ssh/info_refs_receive_pack'), params: { secret_token: '', data: data }, headers: gitlab_shell_internal_api_request_header(secret_token: 'invalid'))

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['error']).to be_nil
          end
        end

        context 'where an exception occurs' do
          it 'responds with 500' do
            expect(git_push_ssh_proxy).to receive(:info_refs_receive_pack).and_raise('deliberate exception raised')

            post api('/geo/proxy_git_ssh/info_refs_receive_pack'), params: { secret_token: secret_token, data: data }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:internal_server_error)
            expect(json_response['message']).to include('RuntimeError (deliberate exception raised)')
            expect(json_response['result']).to be_nil
          end
        end

        context 'with a valid secret token' do
          let(:http_response) { double(Net::HTTPOK, code: 200, body: 'something here') }
          let(:api_response) { Gitlab::Geo::GitSSHProxy::APIResponse.from_http_response(http_response, primary_repo) }

          before do
            # Mocking a real Net::HTTPSuccess is very difficult as it's not
            # easy to instantiate the class due to the way it sets the body
            expect(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          end

          it 'responds with 200' do
            expect(git_push_ssh_proxy).to receive(:info_refs_receive_pack).and_return(api_response)

            post api('/geo/proxy_git_ssh/info_refs_receive_pack'), params: { secret_token: secret_token, data: data }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:ok)
            expect(Base64.decode64(json_response['result'])).to eql('something here')
          end
        end
      end
    end

    describe 'POST /geo/proxy_git_ssh/receive_pack' do
      context 'with all required params missing' do
        it 'responds with 400' do
          post api('/geo/proxy_git_ssh/receive_pack'), params: nil

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eql('secret_token is missing, data is missing, data[gl_id] is missing, data[primary_repo] is missing, output is missing')
        end
      end

      context 'with all required params' do
        let(:output) { Base64.encode64('info_refs content') }
        let(:git_push_ssh_proxy) { double(Gitlab::Geo::GitSSHProxy) }

        before do
          allow(Gitlab::Geo::GitSSHProxy).to receive(:new).with(data).and_return(git_push_ssh_proxy)
        end

        context 'with an invalid jwt token' do
          it 'responds with 401' do
            post(api('/geo/proxy_git_ssh/receive_pack'), params: { secret_token: 'invalid', data: data, output: output }, headers: gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse'))

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['error']).to be_nil
          end
        end

        context 'where an exception occurs' do
          it 'responds with 500' do
            expect(git_push_ssh_proxy).to receive(:receive_pack).and_raise('deliberate exception raised')
            post api('/geo/proxy_git_ssh/receive_pack'), params: { secret_token: secret_token, data: data, output: output }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:internal_server_error)
            expect(json_response['message']).to include('RuntimeError (deliberate exception raised)')
            expect(json_response['result']).to be_nil
          end
        end

        context 'with a valid secret token' do
          let(:http_response) { double(Net::HTTPCreated, code: 201, body: 'something here', class: Net::HTTPCreated) }
          let(:api_response) { Gitlab::Geo::GitSSHProxy::APIResponse.from_http_response(http_response, primary_repo) }

          before do
            # Mocking a real Net::HTTPSuccess is very difficult as it's not
            # easy to instantiate the class due to the way it sets the body
            expect(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          end

          it 'responds with 201' do
            expect(git_push_ssh_proxy).to receive(:receive_pack).with(output).and_return(api_response)

            post api('/geo/proxy_git_ssh/receive_pack'), params: { secret_token: secret_token, data: data, output: output }, headers: gitlab_shell_internal_api_request_header

            expect(response).to have_gitlab_http_status(:created)
            expect(Base64.decode64(json_response['result'])).to eql('something here')
          end
        end
      end
    end
  end

  describe 'GET /geo/proxy' do
    subject { get api('/geo/proxy'), headers: workhorse_headers }

    let(:non_proxy_response_schema) do
      {
        'type' => 'object',
        'additionalProperties' => false,
        'required' => %w(geo_enabled),
        'properties' => {
          'geo_enabled' => { 'type' => 'boolean' }
        }
      }
    end

    let(:proxy_response_schema) do
      non_proxy_response_schema.merge({
        'required' => %w(geo_enabled geo_proxy_url geo_proxy_extra_data),
        'properties' => {
          'geo_enabled' => { 'type' => 'boolean' },
          'geo_proxy_url' => { 'type' => 'string' },
          'geo_proxy_extra_data' => { 'type' => 'string' }
        }
      })
    end

    include_context 'workhorse headers'

    context 'with valid auth' do
      context 'when Geo is not being used' do
        it 'returns empty data' do
          allow(::Gitlab::Geo).to receive(:enabled?).and_return(false)

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to match_schema(non_proxy_response_schema)
          expect(json_response['geo_enabled']).to be_falsey
        end
      end

      context 'when this is a primary site' do
        it 'returns empty data' do
          stub_current_geo_node(primary_node)

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to match_schema(non_proxy_response_schema)
          expect(json_response['geo_enabled']).to be_truthy
        end
      end

      context 'when this is a secondary site with unified URL' do
        let_it_be(:unified_url_secondary_node) { create(:geo_node, url: primary_node.url) }

        before do
          stub_current_geo_node(unified_url_secondary_node)
        end

        context 'when a primary exists' do
          it 'returns the primary internal URL and extra proxy data' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to match_schema(proxy_response_schema)
            expect(json_response['geo_enabled']).to be_truthy
            expect(json_response['geo_proxy_url']).to match(primary_node.internal_url)

            proxy_extra_data = json_response['geo_proxy_extra_data']
            jwt = JWT.decode(proxy_extra_data.split(':').second, unified_url_secondary_node.secret_access_key)
            extra_data = Gitlab::Json.parse(jwt.first['data'])

            expect(proxy_extra_data.split(':').first).to match(unified_url_secondary_node.access_key)
            expect(extra_data).to eq({})
          end
        end

        context 'when a primary does not exist' do
          it 'returns empty data' do
            allow(::Gitlab::Geo).to receive(:primary_node_configured?).and_return(false)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to match_schema(non_proxy_response_schema)
            expect(json_response['geo_enabled']).to be_truthy
          end
        end
      end

      context 'when this is a secondary site with separate URLs' do
        before do
          stub_current_geo_node(secondary_node)
        end

        context 'when a primary does not exist' do
          it 'returns empty data' do
            allow(::Gitlab::Geo).to receive(:primary_node_configured?).and_return(false)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to match_schema(non_proxy_response_schema)
            expect(json_response['geo_enabled']).to be_truthy
          end
        end

        context 'when geo_secondary_proxy_separate_urls feature flag is disabled' do
          before do
            stub_feature_flags(geo_secondary_proxy_separate_urls: false)
          end

          it 'returns empty data' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to match_schema(non_proxy_response_schema)
            expect(json_response['geo_enabled']).to be_truthy
          end
        end

        context 'when geo_secondary_proxy_separate_urls feature flag is enabled' do
          it 'returns the primary internal URL and extra proxy data' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to match_schema(proxy_response_schema)
            expect(json_response['geo_enabled']).to be_truthy
            expect(json_response['geo_proxy_url']).to match(primary_node.internal_url)

            proxy_extra_data = json_response['geo_proxy_extra_data']
            jwt = JWT.decode(proxy_extra_data.split(':').second, secondary_node.secret_access_key)
            extra_data = Gitlab::Json.parse(jwt.first['data'])

            expect(proxy_extra_data.split(':').first).to match(secondary_node.access_key)
            expect(extra_data).to eq({})
          end
        end
      end
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'POST /geo/node_proxy/:id/graphql' do
    let(:headers) { { 'Content-Type' => 'application/json' } }
    let(:unexisting_node_id) { non_existing_record_id }

    before do
      stub_current_geo_node(primary_node)
    end

    it_behaves_like '404 response' do
      let(:request) { post api("/geo/node_proxy/#{unexisting_node_id}/graphql", admin, admin_mode: true) }
    end

    it 'denies access if not admin' do
      post api("/geo/node_proxy/#{secondary_node.id}/graphql", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'requests the graphql endpoint with the post body and returns the output' do
      stub_request(:post, secondary_node.graphql_url)
        .with(body: { input: 'test' })
        .to_return(status: 200, body: { testResponse: 'result' }.to_json, headers: headers)

      post api("/geo/node_proxy/#{secondary_node.id}/graphql", admin, admin_mode: true), params: { input: 'test' }.to_json, headers: headers

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq('testResponse' => 'result')
    end

    it 'returns empty output if remote fails' do
      stub_request(:post, secondary_node.graphql_url)
        .with(body: { input: 'test' })
        .to_return(status: 500)

      post api("/geo/node_proxy/#{secondary_node.id}/graphql", admin, admin_mode: true), params: { input: 'test' }.to_json, headers: headers

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
    end
  end
end
