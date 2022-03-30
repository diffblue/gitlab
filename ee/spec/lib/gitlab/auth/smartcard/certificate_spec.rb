# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Smartcard::Certificate do
  let(:subject_dn) { '/O=Random Corp Ltd/CN=gitlab-user/emailAddress=gitlab-user@random-corp.org' }
  let(:issuer_dn) { '/O=Random Corp Ltd/CN=Random Corp' }
  let(:certificate_header) { 'certificate' }
  let(:openssl_certificate_store) { instance_double(OpenSSL::X509::Store) }
  let(:openssl_certificate) { instance_double(OpenSSL::X509::Certificate, subject: subject_dn, issuer: issuer_dn) }
  let(:user_build_service) { instance_double(Users::BuildService) }

  before do
    allow(described_class).to receive(:store).and_return(openssl_certificate_store)
    allow(OpenSSL::X509::Certificate).to receive(:new).and_return(openssl_certificate)
    allow(openssl_certificate_store).to receive(:verify).and_return(true)
  end

  shared_examples 'a new smartcard identity' do
    it 'creates smartcard identity' do
      expect { subject }.to change { SmartcardIdentity.count }.by(1)

      identity = SmartcardIdentity.find_by(subject: subject_dn, issuer: issuer_dn)
      expect(identity).not_to be_nil
    end
  end

  shared_examples 'an existing user' do
    it 'finds existing user' do
      expect(subject).to eql(user)
    end

    it 'does not create new user' do
      expect { subject }.not_to change { User.count }
    end
  end

  describe '#find_or_create_user' do
    subject { described_class.new(certificate_header).find_or_create_user }

    context 'user and smartcard identity already exist' do
      let(:user) { create(:user) }

      before do
        create(:smartcard_identity, subject: subject_dn, issuer: issuer_dn, user: user)
      end

      it_behaves_like 'an existing user'
    end

    context 'user exists but smartcard identity does not' do
      let!(:user) { create(:user, email: 'gitlab-user@random-corp.org') }

      it_behaves_like 'an existing user'

      it_behaves_like 'a new smartcard identity'

      it 'associates the new smartcard identity with the user' do
        subject

        expect(SmartcardIdentity.first.user).to eql(user)
      end
    end

    context 'user exists but it is using a new smartcard' do
      let_it_be(:user) { create(:user, email: 'gitlab-user@random-corp.org') }
      let_it_be(:old_identity) do
        create(:smartcard_identity,
               subject: 'old_subject',
               issuer: 'old_issuer_dn',
               user: user)
      end

      it_behaves_like 'an existing user'

      it_behaves_like 'a new smartcard identity'

      it 'keeps both identities for the user' do
        subject

        new_identity = SmartcardIdentity.find_by(subject: subject_dn, issuer: issuer_dn)

        expect(user.smartcard_identities).to contain_exactly(new_identity, old_identity)
      end
    end

    context 'user and smartcard identity do not exist' do
      let(:user) { create(:user) }

      before do
        allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)
      end

      shared_examples_for 'creates user' do
        it do
          expect { subject }.to change { User.count }.from(0).to(1)
          expect(User.first.username).to eql('gitlab-user')
          expect(User.first.email).to eql('gitlab-user@random-corp.org')
        end
      end

      it_behaves_like 'creates user'

      context 'when the current minimum password length is different from the default minimum password length' do
        before do
          stub_application_setting minimum_password_length: 21
        end

        it_behaves_like 'creates user'
      end

      it_behaves_like 'a new smartcard identity'

      it 'calls Users::BuildService with correct params' do
        user_params = { name: 'gitlab-user',
                        username: 'gitlab-user',
                        email: 'gitlab-user@random-corp.org',
                        password_automatically_set: true,
                        certificate_subject:  subject_dn,
                        certificate_issuer: issuer_dn,
                        skip_confirmation: true }
        expect(Users::AuthorizedBuildService).to(
          receive(:new)
            .with(nil, hash_including(user_params))
            .and_return(user_build_service))
        expect(user_build_service).to(
          receive(:execute).and_return(user))

        subject
      end

      context 'username generation' do
        context 'uses CN from certificate' do
          let(:subject_dn) { '/CN=Gitlab User/emailAddress=gitlab-user@random-corp.org' }

          it 'creates user with correct username' do
            subject

            expect(User.first.username).to eql('GitlabUser')
          end
        end

        context 'avoids conflicting namespaces' do
          let(:subject_dn) { '/CN=Gitlab User/emailAddress=gitlab-user@random-corp.org' }
          let!(:existing_user) { create(:user, username: 'GitlabUser') }

          it 'creates user with correct usnername' do
            expect { subject }.to change { User.count }.from(1).to(2)
            expect(User.last.username).to eql('GitlabUser1')
          end
        end
      end

      context 'san email defined' do
        let(:san_defined_email) { 'san@domain.email' }

        before do
          allow(Gitlab.config.smartcard).to receive(:san_extensions).and_return(true)

          expect_next_instance_of(Gitlab::Auth::Smartcard::SANExtension) do |san_extension|
            expect(san_extension).to receive(:email_identity).and_return(san_defined_email)
          end
        end

        it 'creates user' do
          expect { subject }.to change { User.count }.from(0).to(1)

          expect(User.first.email).to eql(san_defined_email)
        end
      end
    end

    it_behaves_like 'a valid certificate is required'
  end

  it_behaves_like 'a certificate store'
end
