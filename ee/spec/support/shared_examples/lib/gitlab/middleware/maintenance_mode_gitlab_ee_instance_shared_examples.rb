# frozen_string_literal: true

RSpec.shared_examples 'write access for a read-only GitLab (EE) instance in maintenance mode' do
  include Rack::Test::Methods
  include EE::GeoHelpers
  using RSpec::Parameterized::TableSyntax

  shared_examples_for 'LFS changes are disallowed' do
    where(:description, :path) do
      'LFS request to locks verify' | '/root/rouge.git/info/lfs/locks/verify'
      'LFS request to locks create' | '/root/rouge.git/info/lfs/locks'
      'LFS request to locks unlock' | '/root/rouge.git/info/lfs/locks/1/unlock'
    end

    with_them do
      it "expects a POST #{description} URL not to be allowed" do
        response = request.post(path)

        expect(response).to be_redirect
        expect(subject).to disallow_request
      end

      it "expects a POST #{description} URL with trailing backslash not to be allowed" do
        response = request.post("#{path}/")

        expect(response).to be_redirect
        expect(subject).to disallow_request
      end
    end
  end

  shared_examples_for 'sign in/out and OAuth are allowed' do
    include LdapHelpers
    include LoginHelpers

    before do
      stub_ldap_setting({ enabled: true })
      Rails.application.reload_routes!

      # SAML draws a custom route, LDAP doesn't, so the reload needs to happen before this
      # to prevent overwriting the SAML route.
      stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'])
    end

    after(:all) do
      Rails.application.reload_routes!
    end

    where(:description, :path) do
      'sign in route'       | '/users/sign_in'
      'sign out route'      | '/users/sign_out'
      'oauth token route'   | '/oauth/token'
      'SSO callback route'  | '/users/auth/gitlab/callback'
      'LDAP callback route' | '/users/auth/ldapmain/callback'
      'SAML regular route'  | '/users/auth/saml'
    end

    with_them do
      it "expects a POST to #{description} URL to be allowed" do
        response = request.post(path)

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end

      it "expects a POST to #{description} URL with trailing slash to be allowed" do
        response = request.post("#{path}/")

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end
    end
  end

  include_context 'with a mocked GitLab instance'

  before do
    stub_maintenance_mode_setting(true)
  end

  context 'normal requests to a read-only GitLab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

    it_behaves_like 'allowlisted /admin/geo requests'

    it "expects a PUT request to /api/v4/application/settings to be allowed" do
      response = request.send(:put, "/api/v4/application/settings")

      expect(response).not_to be_redirect
      expect(subject).not_to disallow_request
    end

    it "expects a POST request to /admin/application_settings/general to be allowed" do
      response = request.send(:post, "/admin/application_settings/general")

      expect(response).not_to be_redirect
      expect(subject).not_to disallow_request
    end

    context 'without Geo enabled' do
      it_behaves_like 'LFS changes are disallowed'
      it_behaves_like 'sign in/out and OAuth are allowed'
    end

    context 'on Geo primary' do
      before do
        stub_primary_node
      end

      it_behaves_like 'LFS changes are disallowed'
      it_behaves_like 'sign in/out and OAuth are allowed'

      it "allows Geo node status updates from Geo secondaries" do
        response = request.post("/api/#{API::API.version}/geo/status")

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end
    end

    context 'on Geo secondary' do
      before do
        stub_secondary_node
      end

      where(:description, :path) do
        'LFS request to batch'        | '/root/rouge.git/info/lfs/objects/batch'
        'to geo replication node api' | "/api/#{API::API.version}/geo_replication/designs/resync"
        'Geo sign in'                 | '/users/auth/geo/sign_in'
        'Geo sign out'                | '/users/auth/geo/sign_out'
      end

      with_them do
        it "expects a POST #{description} URL to be allowed" do
          response = request.post(path)

          expect(response).not_to be_redirect
          expect(subject).not_to disallow_request
        end

        it "expects a POST #{description} URL with trailing slash to be allowed" do
          response = request.post("#{path}/")

          expect(response).not_to be_redirect
          expect(subject).not_to disallow_request
        end
      end

      where(:description, :path) do
        'LFS request to locks verify' | '/root/rouge.git/info/lfs/locks/verify'
        'LFS request to locks create' | '/root/rouge.git/info/lfs/locks'
        'LFS request to locks unlock' | '/root/rouge.git/info/lfs/locks/1/unlock'
        'git-receive-pack'            | '/root/rouge.git/git-receive-pack'
        'application settings'        | '/admin/application_settings/general'
      end

      with_them do
        it "expects a POST #{description} URL to not be allowed" do
          response = request.post(path)

          expect(response).to be_redirect
          expect(subject).to disallow_request
        end

        it "expects a POST #{description} URL with traling slash to not be allowed" do
          response = request.post("#{path}/")

          expect(response).to be_redirect
          expect(subject).to disallow_request
        end
      end

      it "expects a PUT request to /api/v4/application/settings to not be allowed" do
        response = request.send(:put, "/api/v4/application/settings")

        expect(response).to be_redirect
        expect(subject).to disallow_request
      end

      it "allows Geo POST GraphQL requests" do
        response = request.post("/api/#{API::API.version}/geo/graphql")

        expect(response).not_to be_redirect
        expect(subject).not_to disallow_request
      end
    end
  end
end
