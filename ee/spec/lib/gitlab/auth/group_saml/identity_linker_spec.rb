# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::IdentityLinker do
  let(:user) { create(:user) }
  let(:provider) { 'group_saml' }
  let(:uid) { user.email }
  let(:in_response_to) { '12345' }
  let(:saml_response) { instance_double(OneLogin::RubySaml::Response, in_response_to: in_response_to) }
  let(:saml_provider) { create(:saml_provider) }
  let(:session) { {} }
  let(:oauth) do
    OmniAuth::AuthHash.new(provider: provider, uid: uid,
                           info: { email: user.email }, extra: { response_object: saml_response })
  end

  subject(:identity_linker) { described_class.new(user, oauth, session, saml_provider) }

  context 'linked identity exists' do
    let!(:identity) do
      user.identities.create!(provider: provider, extern_uid: extern_uid, saml_provider: saml_provider)
    end

    context 'when the extern_uid matches' do
      let(:extern_uid) { uid }

      it "doesn't create new identity" do
        expect { subject.link }.not_to change { Identity.count }
      end

      it "sets #changed? to false" do
        subject.link

        expect(subject).not_to be_changed
      end

      it 'adds user to group' do
        subject.link

        expect(saml_provider.group.member?(user)).to eq(true)
      end
    end

    context 'when the extern_uid does not match' do
      let(:audit_event) { AuditEvent.last.details[:custom_message] }
      let_it_be(:extern_uid) { 'ioKaiph5' }

      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'updates the identity when the email address matches' do
        expect(identity.extern_uid).to eq(extern_uid)

        identity_linker.link

        expect(identity.reload.extern_uid).to eq(uid)
        expect(identity_linker.failed?).to eq(false)
        expect(identity_linker.error_message).to be_empty
        expect(audit_event).to eq("Updated extern_uid from #{extern_uid} to #{uid}")
      end

      it 'does not update the identity when the email address does not match', :aggregate_failures do
        oauth.info.email = generate(:email)

        identity_linker.link

        expect(identity.reload.extern_uid).to eq(extern_uid)
        expect(identity_linker.failed?).to eq(true)
        expect(identity_linker.error_message)
          .to eq(
            s_('GroupSAML|SAML Name ID and email address do not match your user account. Contact an administrator.')
          )
        expect(audit_event).to eq("Failed to update extern_uid from #{extern_uid} to #{uid}")
      end

      context 'when the extern_uid is already taken' do
        before do
          saml_provider.identities.create!(provider: provider, extern_uid: uid, user: create(:user))
        end

        it 'fails and does not update the identity', :aggregate_failures do
          identity_linker.link

          expect(identity.reload.extern_uid).to eq(extern_uid)
          expect(identity_linker.failed?).to eq(true)
          expect(identity_linker.error_message).to eq('Extern uid has already been taken')
          expect(audit_event).to eq("Failed to update extern_uid from #{extern_uid} to #{uid}")
        end
      end
    end
  end

  context 'identity needs to be created' do
    context 'with identity provider initiated request' do
      it 'attempting to link accounts raises an exception' do
        expect { subject.link }.to raise_error(Gitlab::Auth::Saml::IdentityLinker::UnverifiedRequest)
      end
    end

    context 'with valid gitlab initiated request' do
      let(:session) { { 'last_authn_request_id' => in_response_to } }

      it 'creates linked identity' do
        expect { subject.link }.to change { user.identities.count }
      end

      it 'sets identity provider' do
        subject.link

        expect(user.identities.last.provider).to eq provider
      end

      it 'sets saml provider' do
        subject.link

        expect(user.identities.last.saml_provider).to eq saml_provider
      end

      it 'sets identity extern_uid' do
        subject.link

        expect(user.identities.last.extern_uid).to eq uid
      end

      it 'sets #changed? to true' do
        subject.link

        expect(subject).to be_changed
      end

      it 'adds user to group' do
        subject.link

        expect(saml_provider.group.member?(user)).to eq(true)
      end
    end
  end
end
