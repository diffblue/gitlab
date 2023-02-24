# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SmartcardController, type: :request, feature_category: :system_access do
  include LdapHelpers

  let(:smartcard_host) { 'smartcard.example.com' }
  let(:smartcard_port) { 3443 }

  describe '#auth' do
    let(:params) { {} }

    subject { post auth_smartcard_path, params: params }

    before do
      stub_smartcard_config(
        client_certificate_required_host: smartcard_host,
        client_certificate_required_port: smartcard_port
      )
    end

    context 'with smartcard_auth enabled' do
      before do
        enable_smartcard_authentication
      end

      it 'redirects to extract certificate' do
        subject

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response.location).to(
          eq(extract_certificate_smartcard_url(host: smartcard_host,
                                               port: smartcard_port)))
      end

      context 'with provider param' do
        let(:provider) { 'ldap-provider' }
        let(:params) { { provider: provider } }

        it 'forwards the provider param' do
          subject

          expect(response).to have_gitlab_http_status(:redirect)
          expect(response.location).to(
            eq(extract_certificate_smartcard_url(host: smartcard_host,
                                                 port: smartcard_port,
                                                 provider: provider)))
        end
      end
    end

    context 'with smartcard_auth disabled' do
      before do
        allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(false)
      end

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#extract_certificate' do
    let(:certificate) { 'certificate' }
    let(:certificate_headers) { { 'X-SSL-CLIENT-CERTIFICATE': certificate } }
    let(:params) { {} }

    subject do
      get(extract_certificate_smartcard_path, headers: certificate_headers,
                                              params: params)
    end

    before do
      stub_config_setting(host: 'example.com',
                          port: 443)
      stub_smartcard_config(
        client_certificate_required_host: smartcard_host,
        client_certificate_required_port: smartcard_port
      )
      host! "#{smartcard_host}:#{smartcard_port}"
    end

    context 'with smartcard_auth enabled' do
      before do
        enable_smartcard_authentication
      end

      it 'redirects to verify certificate' do
        subject

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response.location).to(
          eq(verify_certificate_smartcard_url(host: ::Gitlab.config.gitlab.host,
                                              port: ::Gitlab.config.gitlab.port,
                                              client_certificate: certificate)))
      end

      context 'with provider param' do
        let(:provider) { 'ldap-provider' }
        let(:params) { { provider: provider } }

        it 'forwards the provider param' do
          subject

          expect(response).to have_gitlab_http_status(:redirect)
          expect(response.location).to(
            eq(verify_certificate_smartcard_url(host: ::Gitlab.config.gitlab.host,
                                                port: ::Gitlab.config.gitlab.port,
                                                client_certificate: certificate,
                                                provider: provider)))
        end
      end

      context 'missing NGINX client certificate header' do
        let(:certificate_headers) { {} }

        it 'renders unauthorized' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'request from different host / port' do
        it 'renders 404' do
          host! 'another.host:42'

          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with smartcard_auth disabled' do
      before do
        allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(false)
      end

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#verify_certificate' do
    shared_examples 'a client certificate authentication' do |auth_method|
      context 'with smartcard_auth enabled' do
        it 'allows sign in' do
          subject

          expect(request.env['warden']).to be_authenticated
        end

        it 'redirects to root' do
          subject

          expect(response).to redirect_to(root_url)
        end

        it 'logs audit event' do
          audit_event_service = instance_double(::AuditEventService)

          # Creating a confirmed user also creates an email corresponding to the user primary email
          expect(::AuditEventService).to(
            receive(:new)
              .with(instance_of(User), instance_of(User), { action: :create }).and_call_original)

          expect(::AuditEventService).to(
            receive(:new)
              .with(instance_of(User), instance_of(User), { with: auth_method, ip_address: '127.0.0.1' })
              .and_return(audit_event_service))
          expect(audit_event_service).to receive_message_chain(:for_authentication, :security_event)

          subject
        end

        it 'stores active session' do
          session_enforcer = instance_double(Gitlab::Auth::Smartcard::SessionEnforcer)

          expect(::Gitlab::Auth::Smartcard::SessionEnforcer).to(
            receive(:new).and_return(session_enforcer))
          expect(session_enforcer).to receive(:update_session)

          subject
        end

        context 'user does not exist' do
          context 'signup allowed' do
            it 'creates user' do
              expect { subject }.to change { User.count }.from(0).to(1)
            end
          end

          context 'signup disabled' do
            it 'renders 401' do
              allow(Gitlab::CurrentSettings.current_application_settings).to(
                receive(:allow_signup?).and_return(false))

              subject

              expect(flash[:alert]).to eql('Failed to signing using smartcard authentication')
              expect(response).to redirect_to(new_user_session_path)
              expect(request.env['warden']).not_to be_authenticated
            end
          end
        end

        context 'missing client certificate param' do
          let(:params) { {} }

          it 'renders unauthorized' do
            subject

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(request.env['warden']).not_to be_authenticated
          end
        end
      end

      context 'with smartcard_auth disabled' do
        before do
          allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(false)
        end

        it 'renders 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    let(:client_certificate) { 'certificate' }
    let(:params) { { client_certificate: client_certificate } }
    let(:serial) { '42' }
    let(:subject_dn) { '/O=Random Corp Ltd/CN=gitlab-user/emailAddress=gitlab-user@random-corp.org' }
    let(:issuer_dn) { 'CN=Random Corp,O=Random Corp Ltd,C=US' }

    before do
      enable_smartcard_authentication
      stub_certificate_store
      stub_certificate
    end

    context 'Smartcard::Certificate' do
      subject { get verify_certificate_smartcard_path, params: params }

      it_behaves_like 'a client certificate authentication', 'smartcard'

      context 'user already exists' do
        before do
          user = create(:user)
          create(:smartcard_identity, subject: subject_dn, issuer: issuer_dn, user: user)
        end

        it 'finds existing user' do
          expect { subject }.not_to change { User.count }
          expect(request.env['warden']).to be_authenticated
        end
      end

      context 'certificate header formats from NGINX' do
        shared_examples 'valid certificate header' do
          it 'authenticates user' do
            expect(Gitlab::Auth::Smartcard::Certificate).to receive(:new).with(expected_certificate).and_call_original

            subject

            expect(request.env['warden']).to be_authenticated
          end
        end

        let(:expected_certificate) { "-----BEGIN CERTIFICATE-----\nrow\nrow\n-----END CERTIFICATE-----" }

        context 'escaped format' do
          let(:client_certificate) { '-----BEGIN%20CERTIFICATE-----%0Arow%0Arow%0A-----END%20CERTIFICATE-----' }

          it_behaves_like 'valid certificate header'
        end

        context 'deprecated format' do
          let(:client_certificate) { '-----BEGIN CERTIFICATE----- row row -----END CERTIFICATE-----' }

          it_behaves_like 'valid certificate header'
        end
      end
    end

    context 'Smartcard::LdapCertificate' do
      let(:ldap_connection) { instance_double(::Net::LDAP) }
      let(:subject_ldap_dn) { 'uid=john doe,ou=people,dc=example,dc=com' }
      let(:ldap_email) { 'john.doe@example.com' }
      let(:ldap_entry) do
        Net::LDAP::Entry.new.tap do |entry|
          entry['dn'] = subject_ldap_dn
          entry['uid'] = 'john doe'
          entry['cn'] = 'John Doe'
          entry['mail'] = ldap_email
        end
      end

      let(:ldap_user_search_scope) { 'dc=example,dc=com' }
      let(:ldap_search_params) do
        { attributes: array_including('dn', 'cn', 'mail', 'uid', 'userid'),
          base: ldap_user_search_scope,
          filter: Net::LDAP::Filter.ex(
            'userCertificate:certificateExactMatch',
            "{ serialNumber #{serial}, issuer \"#{issuer_dn}\" }") }
      end

      subject do
        get(verify_certificate_smartcard_path,
            params: params.merge({ provider: 'ldapmain' }))
      end

      before do
        allow(Net::LDAP).to receive(:new).and_return(ldap_connection)
        allow(ldap_connection).to(
          receive(:search).with(ldap_search_params).and_return([ldap_entry]))
      end

      it_behaves_like 'a client certificate authentication', 'smartcard_ldap'

      it 'sets correct parameters for LDAP search' do
        expect(ldap_connection).to(
          receive(:search).with(ldap_search_params).and_return([ldap_entry]))

        subject
      end

      context 'user already exists' do
        let_it_be(:user) { create(:user) }

        it 'finds existing user' do
          create(:identity, { provider: 'ldapmain',
                              extern_uid: subject_ldap_dn,
                              user: user })

          expect { subject }.not_to change { User.count }

          expect(request.env['warden']).to be_authenticated
        end

        context 'user has a different identity' do
          let(:ldap_email) { user.email }

          before do
            create(:identity, { provider: 'ldapmain',
                                extern_uid: 'different_identity_dn',
                                user: user })
          end

          it "doesn't login a user" do
            subject

            expect(request.env['warden']).not_to be_authenticated
          end

          it "doesn't create a new user entry either" do
            expect { subject }.not_to change { User.count }
          end
        end
      end
    end
  end

  def enable_smartcard_authentication
    allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)
  end

  def stub_smartcard_config(smartcard_settings)
    allow(::Gitlab.config.smartcard).to(receive_messages(smartcard_settings))
  end

  def stub_certificate_store
    openssl_certificate_store = instance_double(OpenSSL::X509::Store)
    allow(Gitlab::Auth::Smartcard::Base).to receive(:store).and_return(openssl_certificate_store)
    allow(openssl_certificate_store).to receive(:verify).and_return(true)
  end

  def stub_certificate
    issuer = instance_double(OpenSSL::X509::Name, to_s: issuer_dn)
    openssl_certificate = instance_double(OpenSSL::X509::Certificate, subject: subject_dn, issuer: issuer, serial: serial)
    allow(OpenSSL::X509::Certificate).to receive(:new).and_return(openssl_certificate)
  end
end
