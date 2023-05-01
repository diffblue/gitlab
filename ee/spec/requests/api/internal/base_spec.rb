# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::Internal::Base do
  include GitlabShellHelpers
  include EE::GeoHelpers
  include APIInternalBaseHelpers
  include NamespaceStorageHelpers

  let_it_be(:primary_url) { 'http://primary.example.com' }
  let_it_be(:secondary_url) { 'http://secondary.example.com' }
  let_it_be(:primary_node, reload: true) { create(:geo_node, :primary, url: primary_url) }
  let_it_be(:secondary_node, reload: true) { create(:geo_node, url: secondary_url) }
  let_it_be_with_reload(:user) { create(:user) }

  describe 'POST /internal/post_receive', :geo do
    let(:key) { create(:key, user: user) }
    let_it_be(:project, reload: true) { create(:project, :repository, :wiki_repo) }

    let(:gl_repository) { "project-#{project.id}" }
    let(:reference_counter) { double('ReferenceCounter') }

    let(:identifier) { 'key-123' }

    let(:valid_params) do
      {
        gl_repository: gl_repository,
        identifier: identifier,
        changes: changes,
        push_options: {}
      }
    end

    let(:branch_name) { 'feature' }

    let(:changes) do
      "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{branch_name}"
    end

    let(:git_push_http) { double('GitPushHttp') }

    before do
      project.add_developer(user)
      allow(described_class).to receive(:identify).and_return(user)
      allow_next_instance_of(Gitlab::Identifier) do |instance|
        allow(instance).to receive(:identify).and_return(user)
      end
      stub_current_geo_node(primary_node)
    end

    context 'when the push was redirected from a Geo secondary to the primary' do
      before do
        expect(Gitlab::Geo::GitPushHttp).to receive(:new).with(identifier, gl_repository).and_return(git_push_http)
        expect(git_push_http).to receive(:fetch_referrer_node).and_return(secondary_node)
      end

      it 'includes a message advising a redirection occurred' do
        redirect_message = <<~STR
        This request to a Geo secondary node will be forwarded to the
        Geo primary node:

          http://primary.example.com/#{project.full_path}.git
        STR

        post api('/internal/post_receive'), params: valid_params, headers: gitlab_shell_internal_api_request_header

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['messages']).to include({
          'type' => 'basic',
          'message' => redirect_message
        })
      end
    end
  end

  describe "POST /internal/allowed" do
    let_it_be(:key) { create(:key, user: user) }

    context "project alias" do
      let(:project) { create(:project, :public, :repository) }
      let(:project_alias) { create(:project_alias, project: project) }

      def check_access_by_alias(alias_name)
        post(
          api("/internal/allowed"),
          params: {
            action: "git-upload-pack",
            key_id: key.id,
            project: alias_name,
            protocol: 'ssh'
          },
          headers: gitlab_shell_internal_api_request_header
        )
      end

      context "without premium license" do
        context "project matches a project alias" do
          before do
            check_access_by_alias(project_alias.name)
          end

          it "does not allow access because project can't be found" do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context "with premium license" do
        before do
          stub_licensed_features(project_aliases: true)
        end

        context "project matches a project alias" do
          before do
            check_access_by_alias(project_alias.name)
          end

          it "allows access" do
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context "project doesn't match a project alias" do
          before do
            check_access_by_alias('some-project')
          end

          it "does not allow access because project can't be found" do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'smartcard session required' do
      let_it_be(:project) { create(:project, :repository, :wiki_repo) }

      subject do
        post(
          api("/internal/allowed"),
          params: { key_id: key.id,
                    project: project.full_path,
                    gl_repository: "project-#{project.id}",
                    action: 'git-upload-pack',
                    protocol: 'ssh' },
          headers: gitlab_shell_internal_api_request_header
        )
      end

      before do
        stub_licensed_features(smartcard_auth: true)
        stub_smartcard_setting(enabled: true, required_for_git_access: true)

        project.add_developer(user)
      end

      context 'user with a smartcard session', :clean_gitlab_redis_sessions do
        let(:session_id) { '42' }
        let(:stored_session) do
          { 'smartcard_signins' => { 'last_signin_at' => 5.minutes.ago } }
        end

        before do
          Gitlab::Redis::Sessions.with do |redis|
            redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
            redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
          end
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'user without a smartcard session' do
        it "does not allow access" do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response['message']).to eql('Project requires smartcard login. Please login to GitLab using a smartcard.')
        end
      end

      context 'with the setting off' do
        before do
          stub_smartcard_setting(required_for_git_access: false)
        end

        it "allows access" do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'ip restriction' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :repository, namespace: group) }

      let(:params) do
        {
          key_id: key.id,
          project: project.full_path,
          gl_repository: "project-#{project.id}",
          action: 'git-upload-pack',
          protocol: 'ssh'
        }
      end

      let(:allowed_ip) { '150.168.0.1' }

      before do
        create(:ip_restriction, group: group, range: allowed_ip)
        stub_licensed_features(group_ip_restriction: true)

        project.add_developer(user)
      end

      context 'with or without check_ip parameter' do
        using RSpec::Parameterized::TableSyntax

        where(:check_ip_present, :ip, :status) do
          false | nil           | 200
          true  | '150.168.0.1' | 200
          true  | '150.168.0.2' | 404
        end

        with_them do
          subject do
            post(
              api('/internal/allowed'),
              params: check_ip_present ? params.merge(check_ip: ip) : params,
              headers: gitlab_shell_internal_api_request_header
            )
          end

          it 'modifies access' do
            subject

            expect(response).to have_gitlab_http_status(status)
          end
        end
      end
    end

    context 'maintenance mode enabled' do
      let_it_be(:project) { create(:project, :repository) }

      before do
        stub_maintenance_mode_setting(true)

        project.add_developer(user)
      end

      context 'when action is git push' do
        it 'returns forbidden' do
          push(key, project)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to be_falsey
          expect(json_response["message"]).to eq(
            'Git push is not allowed because this GitLab instance is currently in (read-only) maintenance mode.'
          )
          expect(user.reload.last_activity_on).to be_nil
        end
      end

      context 'when action is not git push' do
        it 'returns success' do
          pull(key, project)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response["status"]).to be_truthy
        end
      end
    end

    context 'with Deploy Key authentication' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:key) { create(:deploy_key, user: user) }
      let_it_be(:deploy_keys_project) do
        create(:deploy_keys_project, :write_access, project: project, deploy_key: key)
      end

      before_all do
        project.add_developer(user)
      end

      it 'passes the deploy key to the auditor context' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(author: key))

        push(key, project)
      end
    end

    context 'git audit streaming event' do
      it_behaves_like 'sends git audit streaming event' do
        subject { pull(key, project) }
      end
    end

    context 'with a namespace storage size limit', :saas do
      let_it_be(:group, refind: true) { create(:group) }
      let_it_be(:project) { create(:project, :repository, :wiki_repo, group: group) }

      let(:sha_with_2_mb_file) { 'bf12d2567099e26f59692896f73ac819bae45b00' }

      before_all do
        project.add_developer(user)
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        set_storage_size_limit(group, megabytes: 4)
      end

      before do
        enforce_namespace_storage_limit(group)
      end

      context 'with a project' do
        before do
          project.repository.delete_branch('2-mb-file')
        end

        context 'requests without changes' do
          it 'returns ok when the size limit has been exceeded' do
            set_used_storage(group, megabytes: 6)

            push(key, project, changes: '_any')

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["status"]).to eq(true)
          end

          it 'returns ok when the size is under the limit' do
            set_used_storage(group, megabytes: 1)

            push(key, project, changes: '_any')

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["status"]).to eq(true)
          end
        end

        context 'requests with changes' do
          let(:size_checker) { Namespaces::Storage::RootSize.new(group) }

          it 'rejects git push when the size limit has been exceeded' do
            set_used_storage(group, megabytes: 6)

            push(key, project)

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response["status"]).to eq(false)
            expect(json_response["message"]).to eq(size_checker.error_message.push_error)
          end

          it 'rejects git push when the push size would exceed the limit' do
            set_used_storage(group, megabytes: 3)

            push(key, project, changes: "#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response["status"]).to eq(false)
            expect(json_response["message"]).to eq(
              'Your push to this repository has been rejected because ' \
              'it would exceed the namespace storage limit of 4 MB. ' \
              'Reduce your namespace storage or purchase additional storage.'
            )
          end

          it 'accepts git push when the size is under the limit' do
            set_used_storage(group, megabytes: 1)

            push(key, project, changes: "#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["status"]).to eq(true)
          end
        end
      end

      context 'with a snippet' do
        let_it_be(:project_snippet) { create(:project_snippet, :repository, author: user, project: project) }

        let(:snippet_changes) { "#{TestEnv::BRANCH_SHA['snippet/single-file']} #{TestEnv::BRANCH_SHA['snippet/edit-file']} refs/heads/snippet/edit-file" }

        it 'rejects git push when the size limit has been exceeded' do
          set_used_storage(group, megabytes: 6)

          push(key, project_snippet, changes: snippet_changes)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to eq(false)
          expect(json_response["message"]).to eq("You are not allowed to update this snippet.")
        end
      end

      context 'with a wiki' do
        let_it_be(:wiki) { create(:project_wiki, project: project) }

        it 'rejects git push when the size limit has been exceeded' do
          set_used_storage(group, megabytes: 6)

          push(key, wiki)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response["status"]).to eq(false)
          expect(json_response["message"]).to eq("You are not allowed to write to this project's wiki.")
        end
      end
    end

    context 'when namespace storage size limits are enabled only for free namespaces', :saas do
      let_it_be(:group, refind: true) { create(:group) }
      let_it_be(:project) { create(:project, :repository, group: group) }

      let(:sha_with_2_mb_file) { 'bf12d2567099e26f59692896f73ac819bae45b00' }

      before_all do
        project.add_developer(user)
        create(:gitlab_subscription, :ultimate, namespace: group)
      end

      before do
        stub_application_setting(enforce_namespace_storage_limit: true)
        stub_application_setting(automatic_purchased_storage_allocation: true)
        stub_const('::Namespaces::Storage::Enforcement::EFFECTIVE_DATE', 2.years.ago.to_date)
        stub_const('::Namespaces::Storage::Enforcement::ENFORCEMENT_DATE', 1.year.ago.to_date)
        stub_feature_flags(
          namespace_storage_limit: true,
          enforce_storage_limit_for_paid: false,
          enforce_storage_limit_for_free: true,
          namespace_storage_limit_bypass_date_check: false
        )
      end

      context 'with a project in a paid namespace' do
        context 'requests with changes' do
          it 'accepts git push when the project repository size limit has been exceeded but is within the additional purchased storage size' do
            group.update!(additional_purchased_storage_size: 3)
            project.update!(repository_size_limit: 4.megabytes)
            project.statistics.update!(repository_size: 6.megabytes)

            push(key, project)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response["status"]).to eq(true)
          end
        end
      end
    end
  end

  describe "POST /internal/lfs_authenticate", :geo do
    let(:project) { create(:project, :repository) }

    context 'for a secondary node' do
      before do
        stub_lfs_setting(enabled: true)
        stub_current_geo_node(secondary_node)
        project.add_developer(user)
      end

      it 'returns the repository_http_path at the primary node' do
        expect(Project).to receive(:find_by_full_path).and_return(project)

        lfs_auth_user(user.id, project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['repository_http_path']).to eq(geo_primary_http_url_to_repo(project))
      end
    end

    def lfs_auth_user(user_id, project)
      post(
        api("/internal/lfs_authenticate"),
        params: {
          user_id: user_id,
          project: project.full_path
        },
        headers: gitlab_shell_internal_api_request_header
      )
    end
  end

  describe 'POST /internal/personal_access_token' do
    let_it_be(:key) { create(:key, user: user) }

    let(:instance_level_max_personal_access_token_lifetime) { nil }

    before do
      stub_licensed_features(personal_access_token_expiration_policy: !!instance_level_max_personal_access_token_lifetime)
      stub_application_setting(max_personal_access_token_lifetime: instance_level_max_personal_access_token_lifetime)
    end

    context 'with a max token lifetime on the instance' do
      let(:instance_level_max_personal_access_token_lifetime) { 10 }

      it 'returns an error message when the expiry date exceeds the max token lifetime' do
        post api('/internal/personal_access_token'),
             params: {
               key_id: key.id,
               name: 'newtoken',
               scopes: %w(read_api read_repository),
               expires_at: (instance_level_max_personal_access_token_lifetime + 1).days.from_now.to_date.to_s
             },
             headers: gitlab_shell_internal_api_request_header

        aggregate_failures do
          expect(json_response['success']).to eq(false)
          expect(json_response['message']).to eq("Failed to create token: Expires at is invalid")
        end
      end

      it 'returns a valid token when the expiry date does not exceed the max token lifetime' do
        expires_at = instance_level_max_personal_access_token_lifetime.days.from_now.to_date.to_s
        token_size = (PersonalAccessToken.token_prefix || '').size + 20

        post api('/internal/personal_access_token'),
             params: {
               key_id: key.id,
               name: 'newtoken',
               scopes: %w(read_api read_repository),
               expires_at: expires_at
             },
             headers: gitlab_shell_internal_api_request_header

        aggregate_failures do
          expect(json_response['success']).to eq(true)
          expect(json_response['token']).to match(/\A\S{#{token_size}}\z/)
          expect(json_response['scopes']).to match_array(%w(read_api read_repository))
          expect(json_response['expires_at']).to eq(expires_at)
        end
      end
    end
  end

  describe 'POST /internal/two_factor_manual_otp_check' do
    let_it_be(:key) { create(:key, user: user) }

    let(:key_id) { key.id }
    let(:otp) { '123456' }

    before do
      stub_feature_flags(two_factor_for_cli: true)
      stub_licensed_features(git_two_factor_enforcement: true)
    end

    subject do
      post api('/internal/two_factor_manual_otp_check'),
           params: { key_id: key_id, otp_attempt: otp },
           headers: gitlab_shell_internal_api_request_header
    end

    it_behaves_like 'actor key validations'

    context 'when the key is a deploy key' do
      let(:key_id) { create(:deploy_key).id }

      it 'returns an error message' do
        subject

        expect(json_response['success']).to be_falsey
        expect(json_response['message']).to eq('Deploy keys cannot be used for Two Factor')
      end
    end

    context 'when the two factor is enabled' do
      before do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(true) # rubocop:disable RSpec/AnyInstanceOf
      end

      context 'when the OTP is valid' do
        it 'registers a new OTP session and returns success' do
          allow_next_instance_of(Users::ValidateManualOtpService) do |service|
            allow(service).to receive(:execute).with(otp).and_return(status: :success)
          end

          expect_next_instance_of(::Gitlab::Auth::Otp::SessionEnforcer) do |session_enforcer|
            expect(session_enforcer).to receive(:update_session).once
          end

          subject

          expect(json_response['success']).to be_truthy
        end
      end

      context 'when the OTP is invalid' do
        before do
          allow_next_instance_of(Users::ValidateManualOtpService) do |service|
            allow(service).to receive(:execute).with(otp).and_return(status: :error)
          end
        end

        it_behaves_like 'an auditable failed authentication' do
          let(:operation) { subject }
          let(:method) { 'OTP' }
        end

        it 'is not success' do
          subject

          expect(json_response['success']).to be_falsey
        end

        it "locks the user out after maximum attempts is reached" do
          user.update!(failed_attempts: User.maximum_attempts.pred)

          # make invalid request to lock user before next request
          post api('/internal/two_factor_manual_otp_check'),
            params: { key_id: key_id, otp_attempt: otp },
            headers: gitlab_shell_internal_api_request_header

          # user is now locked
          subject

          expect(json_response['success']).to be_falsey
          expect(json_response['message']).to eq 'Your account is locked'
        end

        it "logs the failure" do
          expect(::Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              message: 'Failed OTP login',
              user_id: user.id,
              failed_attempts: user.failed_attempts + 1,
              ip: '127.0.0.1'
            ))
            .and_call_original

          subject
        end
      end
    end

    context 'when the two factor is disabled' do
      before do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(false) # rubocop:disable RSpec/AnyInstanceOf
      end

      it 'returns an error message' do
        subject

        expect(json_response['success']).to be_falsey
        expect(json_response['message']).to eq 'Two-factor authentication is not enabled for this user'
      end
    end

    context 'feature flag is disabled' do
      before do
        stub_feature_flags(two_factor_for_cli: false)
      end

      context 'when two-factor is enabled for the user' do
        it 'returns user two factor config' do
          allow_next_instance_of(User) do |instance|
            allow(instance).to receive(:two_factor_enabled?).and_return(true)
          end

          subject

          expect(json_response['success']).to be_falsey
        end
      end
    end

    context 'licensed feature is not available' do
      before do
        stub_licensed_features(git_two_factor_enforcement: false)
      end

      context 'when two-factor is enabled for the user' do
        it 'returns user two factor config' do
          allow_next_instance_of(User) do |instance|
            allow(instance).to receive(:two_factor_enabled?).and_return(true)
          end

          subject

          expect(json_response['success']).to be_falsey
        end
      end
    end
  end

  describe 'POST /internal/two_factor_push_otp_check' do
    let_it_be(:key) { create(:key, user: user) }

    let(:key_id) { key.id }
    let(:otp) { '123456' }

    before do
      stub_feature_flags(two_factor_for_cli: true)
      stub_licensed_features(git_two_factor_enforcement: true)
    end

    subject do
      post api('/internal/two_factor_push_otp_check'),
           params: { key_id: key_id, otp_attempt: otp },
           headers: gitlab_shell_internal_api_request_header
    end

    it_behaves_like 'actor key validations'

    context 'when the key is a deploy key' do
      let(:key_id) { create(:deploy_key).id }

      it 'returns an error message' do
        subject

        expect(json_response['success']).to be_falsey
        expect(json_response['message']).to eq('Deploy keys cannot be used for Two Factor')
      end
    end

    context 'when the two factor is enabled' do
      before do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(true) # rubocop:disable RSpec/AnyInstanceOf
      end

      context 'when the OTP is valid' do
        it 'registers a new OTP session and returns success' do
          allow_next_instance_of(Users::ValidatePushOtpService) do |service|
            allow(service).to receive(:execute).and_return(status: :success)
          end

          expect_next_instance_of(::Gitlab::Auth::Otp::SessionEnforcer) do |session_enforcer|
            expect(session_enforcer).to receive(:update_session).once
          end

          subject

          expect(json_response['success']).to be_truthy
        end
      end

      context 'when the OTP is invalid' do
        it 'is not success' do
          allow_next_instance_of(Users::ValidatePushOtpService) do |service|
            allow(service).to receive(:execute).and_return(status: :error)
          end

          subject

          expect(json_response['success']).to be_falsey
        end
      end
    end

    context 'when the two factor is disabled' do
      before do
        allow_any_instance_of(User).to receive(:two_factor_enabled?).and_return(false)  # rubocop:disable RSpec/AnyInstanceOf
      end

      it 'returns an error message' do
        subject

        expect(json_response['success']).to be_falsey
        expect(json_response['message']).to eq 'Two-factor authentication is not enabled for this user'
      end
    end

    context 'feature flag is disabled' do
      before do
        stub_feature_flags(two_factor_for_cli: false)
      end

      context 'when two-factor is enabled for the user' do
        it 'returns user two factor config' do
          allow_next_instance_of(User) do |instance|
            allow(instance).to receive(:two_factor_enabled?).and_return(true)
          end

          subject

          expect(json_response['success']).to be_falsey
        end
      end
    end

    context 'licensed feature is not available' do
      before do
        stub_licensed_features(git_two_factor_enforcement: false)
      end

      context 'when two-factor is enabled for the user' do
        it 'returns user two factor config' do
          allow_next_instance_of(User) do |instance|
            allow(instance).to receive(:two_factor_enabled?).and_return(true)
          end

          subject

          expect(json_response['success']).to be_falsey
        end
      end
    end
  end
end
