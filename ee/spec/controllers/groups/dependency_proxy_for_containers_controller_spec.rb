# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DependencyProxyForContainersController do
  include HttpBasicAuthHelpers
  include DependencyProxyHelpers

  let_it_be(:user) { create(:user) }

  let_it_be_with_reload(:saml_provider) { create(:saml_provider, enforced_sso: true) }
  let_it_be_with_reload(:group) { saml_provider.group }
  let_it_be_with_reload(:identity) { create(:group_saml_identity, user: user, saml_provider: saml_provider) }

  let(:token_response) { { status: :success, token: 'abcd1234' } }
  let(:jwt) { build_jwt(user) }
  let(:token_header) { "Bearer #{jwt.encoded}" }

  shared_examples 'when sso is enabled for the group' do |successful_example|
    before do
      stub_licensed_features(group_saml: true)
    end

    context 'group owner' do
      before do
        group.add_owner(user)
      end

      it_behaves_like successful_example
    end

    context 'group reporter' do
      before do
        group.add_reporter(user)
      end

      context 'when git check is enforced' do
        before do
          saml_provider.update_column(:git_check_enforced, true)
        end

        it 'returns not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'with an active session', :clean_gitlab_redis_shared_state do
          let(:session_id) { '42' }
          let(:session_time) { 5.minutes.ago }
          let(:stored_session) do
            { 'active_group_sso_sign_ins' => { saml_provider.id => session_time } }
          end

          before do
            Gitlab::Redis::SharedState.with do |redis|
              redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
              redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
            end
          end

          it_behaves_like successful_example
        end
      end

      context 'when git check is not enforced' do
        it_behaves_like successful_example
      end
    end
  end

  before do
    allow(Gitlab.config.dependency_proxy)
      .to receive(:enabled).and_return(true)

    allow_next_instance_of(DependencyProxy::RequestTokenService) do |instance|
      allow(instance).to receive(:execute).and_return(token_response)
    end

    request.headers['HTTP_AUTHORIZATION'] = token_header
  end

  describe 'GET #manifest' do
    let_it_be(:manifest) { create(:dependency_proxy_manifest) }

    let(:pull_response) { { status: :success, manifest: manifest, from_cache: false } }

    subject(:get_manifest) do
      get :manifest, params: { group_id: group.to_param, image: 'alpine', tag: '3.9.2' }
    end

    before do
      allow_next_instance_of(DependencyProxy::FindOrCreateManifestService) do |instance|
        allow(instance).to receive(:execute).and_return(pull_response)
      end
    end

    it_behaves_like 'when sso is enabled for the group', 'a successful manifest pull'
  end

  describe 'GET #blob' do
    let_it_be(:blob) { create(:dependency_proxy_blob) }

    let(:blob_sha) { blob.file_name.sub('.gz', '') }
    let(:blob_response) { { status: :success, blob: blob, from_cache: false } }

    subject(:get_blob) do
      get :blob, params: { group_id: group.to_param, image: 'alpine', sha: blob_sha }
    end

    before do
      allow_next_instance_of(DependencyProxy::FindOrCreateBlobService) do |instance|
        allow(instance).to receive(:execute).and_return(blob_response)
      end
    end

    it_behaves_like 'when sso is enabled for the group', 'a successful blob pull'
  end
end
