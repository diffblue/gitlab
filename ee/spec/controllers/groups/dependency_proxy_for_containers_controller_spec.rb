# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DependencyProxyForContainersController, feature_category: :dependency_proxy do
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

        context 'with an active session', :clean_gitlab_redis_sessions do
          let(:session_id) { '42' }
          let(:session_time) { 5.minutes.ago }
          let(:stored_session) do
            { 'active_group_sso_sign_ins' => { saml_provider.id => session_time } }
          end

          before do
            Gitlab::Redis::Sessions.with do |redis|
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

  shared_examples 'with ip restriction' do |successful_example|
    before do
      allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
      stub_licensed_features(group_ip_restriction: true)
      group.add_maintainer(user)
    end

    shared_examples 'logging the violation' do
      it 'logs the group and user' do
        expect(::Gitlab::AuthLogger).to receive(:warn).with(
          class: described_class.name,
          message: 'IP restriction violation',
          authenticated_subject_id: authenticated_subject.id,
          authenticated_subject_type: authenticated_subject.class.name,
          authenticated_subject_username: authenticated_subject.username,
          group_id: group.id,
          group_path: group.full_path,
          ip: ::Gitlab::IpAddressState.current
        )

        subject
      end
    end

    context 'in group without restriction' do
      it_behaves_like successful_example

      it 'does not log anything' do
        expect(::Gitlab::AuthLogger).not_to receive(:warn)

        subject
      end
    end

    context 'in group with restriction' do
      let(:range) { '192.168.0.0/24' }
      let(:authenticated_subject) { user }

      before do
        create(:ip_restriction, group: group, range: range)
      end

      context 'with address within the range' do
        it_behaves_like successful_example
      end

      context 'with address outside the range' do
        let(:range) { '10.0.0.0/8' }

        it_behaves_like 'logging the violation'
        it_behaves_like 'returning response status', :not_found

        context 'when user is a deploy token' do
          let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
          let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token, group: group) }

          let(:authenticated_subject) { deploy_token }
          let(:jwt) { build_jwt(deploy_token) }

          it_behaves_like 'logging the violation'
          it_behaves_like 'returning response status', :not_found
        end
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
    let_it_be(:manifest) { create(:dependency_proxy_manifest, group: group) }

    let(:pull_response) { { status: :success, manifest: manifest, from_cache: false } }
    let(:head_response) { { status: :success, digest: manifest.digest, content_type: manifest.content_type } }
    let(:tag) { manifest.file_name.sub('.json', '').split(':').last }

    subject(:get_manifest) do
      get :manifest, params: { group_id: group.to_param, image: 'alpine', tag: tag }
    end

    before do
      allow_next_instance_of(DependencyProxy::FindCachedManifestService) do |instance|
        allow(instance).to receive(:execute).and_return(pull_response)
      end
      allow_next_instance_of(DependencyProxy::HeadManifestService) do |instance|
        allow(instance).to receive(:execute).and_return(head_response)
      end
    end

    it_behaves_like 'when sso is enabled for the group', 'a successful manifest pull'
    it_behaves_like 'with ip restriction', 'a successful manifest pull'
  end

  describe 'GET #blob' do
    let_it_be(:blob) { create(:dependency_proxy_blob, group: group) }

    let(:blob_sha) { blob.file_name.sub('.gz', '') }

    subject(:get_blob) do
      get :blob, params: { group_id: group.to_param, image: 'alpine', sha: blob_sha }
    end

    it_behaves_like 'when sso is enabled for the group', 'a successful blob pull'
    it_behaves_like 'with ip restriction', 'a successful blob pull'
  end
end
