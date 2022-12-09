# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Git HTTP requests', feature_category: :source_code_management do
  include GitHttpHelpers
  include WorkhorseHelpers
  include NamespaceStorageHelpers

  shared_examples_for 'pulls are allowed' do
    specify do
      download(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end
  end

  shared_examples_for 'pushes are allowed' do
    specify do
      upload(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end
  end

  describe "User with no identities" do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository, :private) }
    let(:path) { "#{project.full_path}.git" }

    context "when Kerberos token is provided" do
      let(:env) { { spnego_request_token: 'opaque_request_token' } }

      before do
        allow_any_instance_of(Repositories::GitHttpController).to receive(:allow_kerberos_auth?).and_return(true)
      end

      context "when authentication fails because of invalid Kerberos token" do
        before do
          allow_any_instance_of(Repositories::GitHttpController).to receive(:spnego_credentials!).and_return(nil)
        end

        it "responds with status 401 Unauthorized" do
          download(path, **env) do |response|
            expect(response).to have_gitlab_http_status(:unauthorized)
          end
        end
      end

      context "when authentication fails because of unknown Kerberos identity" do
        before do
          allow_any_instance_of(Repositories::GitHttpController).to receive(:spnego_credentials!).and_return("mylogin@FOO.COM")
        end

        it "responds with status 401 Unauthorized" do
          download(path, **env) do |response|
            expect(response).to have_gitlab_http_status(:unauthorized)
          end
        end
      end

      context "when authentication succeeds" do
        before do
          allow_any_instance_of(Repositories::GitHttpController).to receive(:spnego_credentials!).and_return("mylogin@FOO.COM")
          user.identities.create!(provider: "kerberos", extern_uid: "mylogin@FOO.COM")
        end

        context "when the user has access to the project" do
          before do
            project.add_maintainer(user)
          end

          context "when the user is blocked" do
            before do
              user.block
              project.add_maintainer(user)
            end

            it "responds with status 403 Forbidden" do
              download(path, **env) do |response|
                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context "when the user isn't blocked", :redis do
            it "responds with status 200 OK" do
              download(path, **env) do |response|
                expect(response).to have_gitlab_http_status(:ok)
              end
            end

            it 'updates the user last activity' do
              expect(user.last_activity_on).to be_nil

              download(path, **env) do |_response|
                expect(user.reload.last_activity_on).to eql(Date.today)
              end
            end
          end

          it "complies with RFC4559" do
            allow_any_instance_of(Repositories::GitHttpController).to receive(:spnego_response_token).and_return("opaque_response_token")
            download(path, **env) do |response|
              expect(response.headers['WWW-Authenticate'].split("\n")).to include("Negotiate #{::Base64.strict_encode64('opaque_response_token')}")
            end
          end
        end

        context "when the user doesn't have access to the project" do
          it "responds with status 404 Not Found" do
            download(path, **env) do |response|
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          it "complies with RFC4559" do
            allow_any_instance_of(Repositories::GitHttpController).to receive(:spnego_response_token).and_return("opaque_response_token")
            download(path, **env) do |response|
              expect(response.headers['WWW-Authenticate'].split("\n")).to include("Negotiate #{::Base64.strict_encode64('opaque_response_token')}")
            end
          end
        end
      end
    end

    context 'when license is not provided' do
      let(:env) { { user: user.username, password: user.password } }

      before do
        allow(License).to receive(:current).and_return(nil)

        project.add_maintainer(user)
      end

      it_behaves_like 'pulls are allowed'
      it_behaves_like 'pushes are allowed'
    end
  end

  describe 'when SSO is enforced' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, :repository, :private, group: group) }
    let(:env) { { user: user.username, password: user.password } }
    let(:path) { "#{project.full_path}.git" }

    before do
      project.add_developer(user)
      create(:saml_provider, group: group, enforced_sso: true)
    end

    it_behaves_like 'pulls are allowed'
  end

  describe 'when user cannot use password-based login' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, :private, group: group) }
    let_it_be(:user) { create(:user, provisioned_by_group: group) }

    let(:env) { { user: user.username, password: user.password } }
    let(:path) { "#{project.full_path}.git" }

    before do
      project.add_developer(user)
    end

    context 'with feature flag switched off' do
      before do
        stub_feature_flags(block_password_auth_for_saml_users: false)
      end

      it_behaves_like 'pulls are allowed'
      it_behaves_like 'pushes are allowed'
    end

    context 'with feature flag switched on' do
      it 'responds with status 401 Unauthorized for pull action' do
        download(path, **env) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      it 'responds with status 401 Unauthorized for push action' do
        upload(path, **env) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when username and personal access token are provided' do
        let(:user) { create(:user, provisioned_by_group: group) }
        let(:access_token) { create(:personal_access_token, user: user) }
        let(:env) { { user: user.username, password: access_token.token } }

        it_behaves_like 'pulls are allowed'
        it_behaves_like 'pushes are allowed'
      end

      context 'when user has 2FA enabled' do
        let(:user) { create(:user, :two_factor, provisioned_by_group: group) }
        let(:access_token) { create(:personal_access_token, user: user) }

        context 'when username and personal access token are provided' do
          let(:env) { { user: user.username, password: access_token.token } }

          it_behaves_like 'pulls are allowed'
          it_behaves_like 'pushes are allowed'

          it 'rejects the push attempt for read_repository scope' do
            read_access_token = create(:personal_access_token, user: user, scopes: [:read_repository])

            upload(path, user: user.username, password: read_access_token.token) do |response|
              expect(response).to have_gitlab_http_status(:forbidden)
              expect(response.body).to include('You are not allowed to upload code')
            end
          end

          it 'accepts the push attempt for write_repository scope' do
            write_access_token = create(:personal_access_token, user: user, scopes: [:write_repository])

            upload(path, user: user.username, password: write_access_token.token) do |response|
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it 'accepts the pull attempt for read_repository scope' do
            read_access_token = create(:personal_access_token, user: user, scopes: [:read_repository])

            download(path, user: user.username, password: read_access_token.token) do |response|
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it 'accepts the pull attempt for api scope' do
            read_access_token = create(:personal_access_token, user: user, scopes: [:api])

            download(path, user: user.username, password: read_access_token.token) do |response|
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it 'accepts the push attempt for api scope' do
            write_access_token = create(:personal_access_token, user: user, scopes: [:api])

            upload(path, user: user.username, password: write_access_token.token) do |response|
              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end
    end
  end

  describe 'when namespace storage limits are enforced', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:group, refind: true) { create(:group) }
    let_it_be(:project) { create(:project, :repository, :private, group: group) }

    let(:path) { "#{project.full_path}.git" }
    let(:env) { { user: user.username, password: user.password } }

    before_all do
      create(:gitlab_subscription, :ultimate, namespace: group)
      create(:namespace_root_storage_statistics, namespace: group)
      project.add_developer(user)
    end

    before do
      enforce_namespace_storage_limit(group)
      set_storage_size_limit(group, megabytes: 8)
    end

    it_behaves_like 'pushes are allowed'

    context 'when the limit has been exceeded' do
      before do
        set_used_storage(group, megabytes: 14)
      end

      it_behaves_like 'pushes are allowed'
    end
  end
end
