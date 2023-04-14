# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::GitSSHProxy, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  # TODO This spec doesn't work with a relative_url_root https://gitlab.com/gitlab-org/gitlab/issues/11173
  # TODO This spec doesn't work with non-localhost
  let_it_be(:primary_node) { create(:geo_node, :primary, url: 'http://localhost:3001') }
  let_it_be(:secondary_node) { create(:geo_node, url: 'http://localhost:3002') }

  let(:current_node) { nil }
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:key) { create(:key, user: user) }
  let(:key_identifier) { "key-#{key.id}" }
  let(:base_request) { double(Gitlab::Geo::BaseRequest.new.authorization) }

  let(:info_refs_body_short) do
    "008f43ba78b7912f7bf7ef1d7c3b8a0e5ae14a759dfa refs/heads/masterreport-status delete-refs side-band-64k quiet atomic ofs-delta agent=git/2.26.0\n0000"
  end

  let(:base_headers) do
    {
      'Authorization' => 'secret'
    }
  end

  let(:primary_repo_http) { geo_primary_http_internal_url_to_repo(project) }
  let(:primary_repo_ssh) { geo_primary_ssh_url_to_repo(project) }

  let(:data) do
    {
      'gl_id' => "key-#{key.id}",
      'primary_repo' => primary_repo_http
    }
  end

  let(:irrelevant_encoded_message) { Base64.encode64('irrelevant') }

  context 'instance methods' do
    subject { described_class.new(data) }

    before do
      stub_current_geo_node(current_node)

      allow(Gitlab::Geo::BaseRequest).to receive(:new).and_return(base_request)
      allow(base_request).to receive(:authorization).and_return('secret')
    end

    shared_examples 'must be a secondary' do
      it 'raises an exception' do
        expect do
          subject.info_refs_receive_pack
        end.to raise_error(described_class::MustBeASecondaryNode, 'Node is not a secondary or there is no primary Geo node')
      end
    end

    describe '#info_refs_upload_pack' do
      context 'against primary node' do
        let(:current_node) { primary_node }

        it_behaves_like 'must be a secondary'
      end

      context 'against a secondary node' do
        let(:current_node) { secondary_node }

        let(:full_info_refs_upload_pack_url) { "#{primary_repo_http}/info/refs?service=git-upload-pack" }
        let(:info_refs_upload_pack_http_body_full) { "001e# service=git-upload-pack\n0000#{info_refs_body_short}" }

        context 'authorization header is scoped' do
          it 'passes the scope when .info_refs_upload_pack is called' do
            expect(Gitlab::Geo::BaseRequest).to receive(:new).with(scope: project.repository.full_path, gl_id: key_identifier)

            subject.info_refs_upload_pack
          end

          it 'passes the scope when .receive_pack is called' do
            expect(Gitlab::Geo::BaseRequest).to receive(:new).with(scope: project.repository.full_path, gl_id: key_identifier)

            subject.receive_pack(info_refs_body_short)
          end
        end

        context 'with a failed response' do
          let(:error_msg) { 'execution expired' }

          before do
            stub_request(:get, full_info_refs_upload_pack_url).to_timeout
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.info_refs_upload_pack).to be_a(Gitlab::Geo::GitSSHProxy::FailedAPIResponse)
          end

          it 'has a code of 500' do
            expect(subject.info_refs_upload_pack.code).to be(500)
          end

          it 'has a status of false' do
            expect(subject.info_refs_upload_pack.body[:status]).to be_falsey
          end

          it 'has a message' do
            expect(subject.info_refs_upload_pack.body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.info_refs_upload_pack.body[:result]).to be_nil
          end
        end

        context 'with an invalid response' do
          let(:error_msg) { 'dial unix /Users/ash/src/gdk/gdk-ee/gitlab.socket: connect: connection refused' }

          before do
            stub_request(:get, full_info_refs_upload_pack_url).to_return(status: 502, body: error_msg)
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.info_refs_upload_pack).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
          end

          it 'has a code of 502' do
            expect(subject.info_refs_upload_pack.code).to be(502)
          end

          it 'has a status of false' do
            expect(subject.info_refs_upload_pack.body[:status]).to be_falsey
          end

          it 'has a message' do
            expect(subject.info_refs_upload_pack.body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.info_refs_upload_pack.body[:result]).to be_nil
          end
        end

        context 'with a valid response' do
          before do
            stub_request(:get, full_info_refs_upload_pack_url).to_return(status: 200, body: info_refs_upload_pack_http_body_full)
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::APIResponse' do
            expect(subject.info_refs_upload_pack).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
          end

          it 'has a code of 200' do
            expect(subject.info_refs_upload_pack.code).to be(200)
          end

          it 'has a status of true' do
            expect(subject.info_refs_upload_pack.body[:status]).to be_truthy
          end

          it 'has no message' do
            expect(subject.info_refs_upload_pack.body[:message]).to be_nil
          end

          it 'returns a modified body' do
            expect(subject.info_refs_upload_pack.body[:result]).to eql(Base64.encode64(info_refs_body_short))
          end
        end
      end
    end

    describe '#upload_pack' do
      context 'against primary node' do
        let(:current_node) { primary_node }

        it_behaves_like 'must be a secondary'
      end

      context 'against a secondary node' do
        let(:current_node) { secondary_node }

        let(:full_git_upload_pack_url) { "#{primary_repo_http}/git-upload-pack" }
        let(:upload_pack_headers) do
          base_headers.merge(
            'Content-Type' => 'application/x-git-upload-pack-request',
            'Accept' => 'application/x-git-upload-pack-result'
          )
        end

        context 'with a failed response' do
          let(:error_msg) { 'execution expired' }

          before do
            stub_request(:post, full_git_upload_pack_url).to_timeout
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.upload_pack(irrelevant_encoded_message)).to be_a(Gitlab::Geo::GitSSHProxy::FailedAPIResponse)
          end

          it 'has a message' do
            expect(subject.upload_pack(irrelevant_encoded_message).body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.upload_pack(irrelevant_encoded_message).body[:result]).to be_nil
          end
        end

        context 'with an invalid response' do
          let(:error_msg) { 'dial unix /Users/ash/src/gdk/gdk-ee/gitlab.socket: connect: connection refused' }

          before do
            stub_request(:post, full_git_upload_pack_url).to_return(status: 502, body: error_msg, headers: upload_pack_headers)
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.upload_pack(irrelevant_encoded_message)).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
          end

          it 'has a message' do
            expect(subject.upload_pack(irrelevant_encoded_message).body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.upload_pack(irrelevant_encoded_message).body[:result]).to be_nil
          end
        end

        context 'with a valid response' do
          context 'for a git clone operation' do
            let(:base64_encoded_response) { Base64.encode64("0090want 13f347b1231b3120c47b8ca7f06dd8b4e021cf6b multi_ack_detailed side-band-64k thin-pack ofs-delta deepen-since deepen-not agent=git/2.26.0\n0032want 13f347b1231b3120c47b8ca7f06dd8b4e021cf6b\n00000009done\n") }

            let(:decoded_response) { "0090want 13f347b1231b3120c47b8ca7f06dd8b4e021cf6b multi_ack_detailed side-band-64k thin-pack ofs-delta deepen-since deepen-not agent=git/2.26.0\n0000\n00000009done\n" }
            let(:base64_encoded_expected_body) { Base64.encode64(decoded_response) }

            before do
              stub_request(:post, full_git_upload_pack_url).to_return(status: 201, body: decoded_response, headers: upload_pack_headers)
            end

            it 'returns a Gitlab::Geo::GitSSHProxy::APIResponse' do
              expect(subject.upload_pack(base64_encoded_response)).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
            end

            it 'has a code of 201' do
              expect(subject.upload_pack(base64_encoded_response).code).to be(201)
            end

            it 'has no message' do
              expect(subject.upload_pack(base64_encoded_response).body[:message]).to be_nil
            end

            it 'has a result' do
              expect(subject.upload_pack(base64_encoded_response).body[:result]).to eql(base64_encoded_expected_body)
            end
          end

          context 'for a git pull operation' do
            let(:base64_encoded_response) { Base64.encode64("009cwant af3551b2213219f07ab3adaa4bbd22c7c2638010 multi_ack_detailed side-band-64k thin-pack include-tag ofs-delta deepen-since deepen-not agent=git/2.26.0\n00000032have 13f347b1231b3120c47b8ca7f06dd8b4e021cf6b\n0032have 8195a05c3707e28af2ad4d3512f0fdee4c0bd3ee\n0032have 11f60ba825dbe91eebb5ea1701e3b404c0409e21\n0032have a1f474b6173894844dccb70634d8a593f9d0122f\n0032have b6bd59aa5e9511f6685d5f5e362344f74cb8bd9c\n0032have 1caf913d6fb1acbbed004242bb2455dc67ababd9\n0032have 8a84d3ef290f6d0e5060ecbd2f7a5ffb914b2a6b\n0032have 46ad1c9f39ee9ed35e473263b51ec0522d392a3f\n0032have 16c89af2a83438854c438fb5142493c9fdf96449\n0032have 19fff49349aa6d3a74120182b849a5bf7f3962d8\n0032have db70951afb1563340490f720638ce84e13efb186\n0032have 022fbf7856bffb6b090ac818a23d1ea3e77b4609\n0032have e45b528d0fa7ea8af0085ceb90beff01cd1681e4\n0032have 0b2c3606420b8b511e7761177d30066a11350460\n0032have 440a9dfb6dd7dd8bb5a577026492c9a68aad7f2a\n0032have 71e5d9ef406fae17f944a956dc68b078ddffb65d\n0000") }

            let(:decoded_response) { "009cwant af3551b2213219f07ab3adaa4bbd22c7c2638010 multi_ack_detailed side-band-64k thin-pack include-tag ofs-delta deepen-since deepen-not agent=git/2.26.0\n00000032have 13f347b1231b3120c47b8ca7f06dd8b4e021cf6b\n0032have 8195a05c3707e28af2ad4d3512f0fdee4c0bd3ee\n0032have 11f60ba825dbe91eebb5ea1701e3b404c0409e21\n0032have a1f474b6173894844dccb70634d8a593f9d0122f\n0032have b6bd59aa5e9511f6685d5f5e362344f74cb8bd9c\n0032have 1caf913d6fb1acbbed004242bb2455dc67ababd9\n0032have 8a84d3ef290f6d0e5060ecbd2f7a5ffb914b2a6b\n0032have 46ad1c9f39ee9ed35e473263b51ec0522d392a3f\n0032have 16c89af2a83438854c438fb5142493c9fdf96449\n0032have 19fff49349aa6d3a74120182b849a5bf7f3962d8\n0032have db70951afb1563340490f720638ce84e13efb186\n0032have 022fbf7856bffb6b090ac818a23d1ea3e77b4609\n0032have e45b528d0fa7ea8af0085ceb90beff01cd1681e4\n0032have 0b2c3606420b8b511e7761177d30066a11350460\n0032have 440a9dfb6dd7dd8bb5a577026492c9a68aad7f2a\n0032have 71e5d9ef406fae17f944a956dc68b078ddffb65d\n0009done\n0000" }
            let(:base64_encoded_expected_body) { Base64.encode64(decoded_response) }

            before do
              stub_request(:post, full_git_upload_pack_url).to_return(status: 201, body: decoded_response, headers: upload_pack_headers)
            end

            it 'returns a Gitlab::Geo::GitSSHProxy::APIResponse' do
              expect(subject.upload_pack(base64_encoded_response)).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
            end

            it 'has a code of 201' do
              expect(subject.upload_pack(base64_encoded_response).code).to be(201)
            end

            it 'has no message' do
              expect(subject.upload_pack(base64_encoded_response).body[:message]).to be_nil
            end

            it 'has a result' do
              expect(subject.upload_pack(base64_encoded_response).body[:result]).to eql(base64_encoded_expected_body)
            end
          end
        end
      end
    end

    describe '#info_refs_receive_pack' do
      context 'against primary node' do
        let(:current_node) { primary_node }

        it_behaves_like 'must be a secondary'
      end

      context 'against secondary node' do
        let(:current_node) { secondary_node }

        let(:full_info_refs_receive_pack_url) { "#{primary_repo_http}/info/refs?service=git-receive-pack" }
        let(:info_refs_receive_pack_http_body_full) { "001f# service=git-receive-pack\n0000#{info_refs_body_short}" }

        context 'authorization header is scoped' do
          it 'passes the scope when .info_refs_receive_pack is called' do
            expect(Gitlab::Geo::BaseRequest).to receive(:new).with(scope: project.repository.full_path, gl_id: key_identifier)

            subject.info_refs_receive_pack
          end

          it 'passes the scope when .receive_pack is called' do
            expect(Gitlab::Geo::BaseRequest).to receive(:new).with(scope: project.repository.full_path, gl_id: key_identifier)

            subject.receive_pack(info_refs_body_short)
          end
        end

        context 'with a failed response' do
          let(:error_msg) { 'execution expired' }

          before do
            stub_request(:get, full_info_refs_receive_pack_url).to_timeout
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.info_refs_receive_pack).to be_a(Gitlab::Geo::GitSSHProxy::FailedAPIResponse)
          end

          it 'has a code of 500' do
            expect(subject.info_refs_receive_pack.code).to be(500)
          end

          it 'has a status of false' do
            expect(subject.info_refs_receive_pack.body[:status]).to be_falsey
          end

          it 'has a message' do
            expect(subject.info_refs_receive_pack.body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.info_refs_receive_pack.body[:result]).to be_nil
          end
        end

        context 'with an invalid response' do
          let(:error_msg) { 'dial unix /Users/ash/src/gdk/gdk-ee/gitlab.socket: connect: connection refused' }

          before do
            stub_request(:get, full_info_refs_receive_pack_url).to_return(status: 502, body: error_msg)
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.info_refs_receive_pack).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
          end

          it 'has a code of 502' do
            expect(subject.info_refs_receive_pack.code).to be(502)
          end

          it 'has a status of false' do
            expect(subject.info_refs_receive_pack.body[:status]).to be_falsey
          end

          it 'has a message' do
            expect(subject.info_refs_receive_pack.body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.info_refs_receive_pack.body[:result]).to be_nil
          end
        end

        context 'with a valid response' do
          before do
            stub_request(:get, full_info_refs_receive_pack_url).to_return(status: 200, body: info_refs_receive_pack_http_body_full)
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::APIResponse' do
            expect(subject.info_refs_receive_pack).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
          end

          it 'has a code of 200' do
            expect(subject.info_refs_receive_pack.code).to be(200)
          end

          it 'has a status of true' do
            expect(subject.info_refs_receive_pack.body[:status]).to be_truthy
          end

          it 'has no message' do
            expect(subject.info_refs_receive_pack.body[:message]).to be_nil
          end

          it 'returns a modified body' do
            expect(subject.info_refs_receive_pack.body[:result]).to eql(Base64.encode64(info_refs_body_short))
          end
        end
      end
    end

    describe '#receive_pack' do
      context 'against primary node' do
        let(:current_node) { primary_node }

        it_behaves_like 'must be a secondary'
      end

      context 'against secondary node' do
        let(:current_node) { secondary_node }

        let(:full_git_receive_pack_url) { "#{primary_repo_http}/git-receive-pack" }
        let(:receive_pack_headers) do
          base_headers.merge(
            'Content-Type' => 'application/x-git-receive-pack-request',
            'Accept' => 'application/x-git-receive-pack-result'
          )
        end

        context 'with a failed response' do
          let(:error_msg) { 'execution expired' }

          before do
            stub_request(:post, full_git_receive_pack_url).to_timeout
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.receive_pack(irrelevant_encoded_message)).to be_a(Gitlab::Geo::GitSSHProxy::FailedAPIResponse)
          end

          it 'has a message' do
            expect(subject.receive_pack(irrelevant_encoded_message).body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.receive_pack(irrelevant_encoded_message).body[:result]).to be_nil
          end
        end

        context 'with an invalid response' do
          let(:error_msg) { 'dial unix /Users/ash/src/gdk/gdk-ee/gitlab.socket: connect: connection refused' }

          before do
            stub_request(:post, full_git_receive_pack_url).to_return(status: 502, body: error_msg, headers: receive_pack_headers)
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::FailedAPIResponse' do
            expect(subject.receive_pack(irrelevant_encoded_message)).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
          end

          it 'has a message' do
            expect(subject.receive_pack(irrelevant_encoded_message).body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.receive_pack(irrelevant_encoded_message).body[:result]).to be_nil
          end
        end

        context 'with a valid response' do
          let(:decoded_response) { "0095bc3b8ba91de3ecd161440326eda0b89a3c91d339 fc02c3ed8ef0b2dc7cc6e3e3bcf6b13465fea91b refs/heads/master report-status side-band-64k agent=git/2.26.00000PACK<binary>" }
          let(:base64_encoded_response) { decoded_response }

          let(:base64_encoded_expected_body) { Base64.encode64(decoded_response) }

          before do
            stub_request(:post, full_git_receive_pack_url).to_return(status: 201, body: decoded_response, headers: receive_pack_headers)
          end

          it 'returns a Gitlab::Geo::GitSSHProxy::APIResponse' do
            expect(subject.receive_pack(base64_encoded_response)).to be_a(Gitlab::Geo::GitSSHProxy::APIResponse)
          end

          it 'has a code of 201' do
            expect(subject.receive_pack(base64_encoded_response).code).to be(201)
          end

          it 'has no message' do
            expect(subject.receive_pack(base64_encoded_response).body[:message]).to be_nil
          end

          it 'has a result' do
            expect(subject.receive_pack(base64_encoded_response).body[:result]).to eql(base64_encoded_expected_body)
          end
        end
      end
    end
  end
end
