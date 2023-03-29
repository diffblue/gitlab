# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::User do
  include LdapHelpers

  describe 'login through kerberos with linkable LDAP user' do
    let(:uid)        { 'foo' }
    let(:provider)   { 'kerberos' }
    let(:realm)      { 'ad.example.com' }
    let(:base_dn)    { 'ou=users,dc=ad,dc=example,dc=com' }
    let(:info_hash)  { { email: uid + '@' + realm, username: uid } }
    let(:auth_hash)  { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash) }
    let(:oauth_user) { described_class.new(auth_hash) }
    let(:real_email) { 'myname@example.com' }

    before do
      allow(::Gitlab::Kerberos::Authentication).to receive(:kerberos_default_realm).and_return(realm)
      allow(Gitlab.config.omniauth).to receive_messages(auto_link_ldap_user: true, allow_single_sign_on: ['kerberos'])
      stub_ldap_config(base: base_dn)

      ldap_entry = Net::LDAP::Entry.new("uid=#{uid}," + base_dn).tap do |entry|
        entry['uid'] = uid
        entry['email'] = real_email
      end

      stub_ldap_person_find_by_uid(uid, ldap_entry)

      oauth_user.save # rubocop:disable Rails/SaveBang
    end

    it 'links the LDAP person to the GitLab user' do
      gl_user = oauth_user.gl_user

      identities = gl_user.identities.map do |identity|
        { provider: identity.provider, extern_uid: identity.extern_uid }
      end

      expect(identities).to contain_exactly(
        { provider: 'ldapmain', extern_uid: "uid=#{uid},#{base_dn}" },
        { provider: 'kerberos', extern_uid: uid + '@' + realm }
      )

      expect(gl_user.email).to eq(real_email)
    end

    describe '#save' do
      let(:user) { build(:omniauth_user, :blocked_pending_approval) }

      before do
        allow(oauth_user).to receive(:gl_user).and_return(user)
      end

      subject(:save_user) { oauth_user.save } # rubocop: disable Rails/SaveBang

      describe '#activate_user_if_user_cap_not_reached' do
        context 'when a user can be activated based on user cap' do
          before do
            allow(user).to receive(:activate_based_on_user_cap?).and_return(true)
          end

          context 'when the user cap has not been reached yet' do
            it 'activates the user' do
              allow(::User).to receive(:user_cap_reached?).and_return(false)
              expect(oauth_user).to receive(:log_user_changes).with(
                user, 'OAuth', 'user cap not reached yet, unblocking'
              )

              expect do
                save_user
                user.reload
              end.to change { user.state }.from('blocked_pending_approval').to('active')
            end
          end

          context 'when the user cap has been reached' do
            it 'leaves the user as blocked' do
              allow(::User).to receive(:user_cap_reached?).and_return(true)
              expect(oauth_user).not_to receive(:log_user_changes)

              expect do
                save_user
                user.reload
              end.not_to change { user.state }
              expect(user.state).to eq('blocked_pending_approval')
            end
          end
        end

        context 'when a user cannot be activated based on user cap' do
          before do
            allow(user).to receive(:activate_based_on_user_cap?).and_return(false)
          end

          it 'leaves the user as blocked' do
            expect(oauth_user).not_to receive(:log_user_changes)

            expect do
              save_user
              user.reload
            end.not_to change { user.state }
            expect(user.state).to eq('blocked_pending_approval')
          end
        end
      end
    end
  end

  describe '#build_new_user', feature_category: :insider_threat do
    subject(:oauth_user) { described_class.new(OmniAuth::AuthHash.new(info: {})) }

    context 'when identity verification is not enabled' do
      it 'confirms the user' do
        expect(oauth_user.gl_user).to be_confirmed
      end
    end

    context 'when identity verification is enabled' do
      before do
        allow_next_instance_of(User) do |user|
          allow(user).to receive(:identity_verification_enabled?).and_return(true)
        end
      end

      it 'does not confirm the user' do
        expect(oauth_user.gl_user).not_to be_confirmed
      end
    end
  end

  describe '#identity_verification_enabled?', feature_category: :insider_threat do
    subject(:oauth_user) { described_class.new(OmniAuth::AuthHash.new(info: {})) }

    context 'when identity verification is not enabled' do
      before do
        allow_next_instance_of(User) do |user|
          allow(user).to receive(:identity_verification_enabled?).and_return(false)
        end
      end

      it 'is false' do
        expect(subject.identity_verification_enabled?(oauth_user.gl_user)).to eq(false)
      end
    end

    context 'when identity verification is enabled' do
      before do
        allow_next_instance_of(User) do |user|
          allow(user).to receive(:identity_verification_enabled?).and_return(true)
        end
      end

      it 'is true' do
        expect(subject.identity_verification_enabled?(oauth_user.gl_user)).to eq(true)
      end
    end
  end
end
