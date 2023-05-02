# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::User, feature_category: :system_access do
  let(:oidc_user) { described_class.new(auth_hash) }
  let(:gl_user) { oidc_user.gl_user }

  let(:user_groups) { nil }
  let(:oidc_groups_attribute) { 'groups' }
  let(:oidc_required_groups) { [] }
  let(:oidc_admin_groups) { [] }
  let(:oidc_external_groups) { [] }

  let(:info_hash) do
    {
      email: 'john@example.com',
      name: 'John Doe'
    }
  end

  let(:extra_hash) { { raw_info: { groups: user_groups } } }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      uid: 'my-uid',
      provider: 'openid_connect',
      info: info_hash,
      extra: extra_hash)
  end

  before do
    allow(Gitlab.config.omniauth).to receive_messages(block_auto_created_users: false)

    allow_next_instance_of(Gitlab::Auth::Oidc::Config) do |config|
      allow(config).to receive_messages({ groups_attribute: oidc_groups_attribute,
                                          required_groups: oidc_required_groups,
                                          admin_groups: oidc_admin_groups,
                                          external_groups: oidc_external_groups })
    end
  end

  describe '#save' do
    context 'for required groups' do
      context 'when not defined' do
        it 'lets anyone in' do
          oidc_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_valid
        end
      end

      context 'when defined' do
        let(:oidc_required_groups) { ['ArchitectureAstronauts'] }

        context 'when user has correct required groups membership' do
          let(:user_groups) { oidc_required_groups }

          it 'lets members in' do
            oidc_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
          end
        end

        context 'when user is missing required groups membership' do
          it 'does not allow non-members' do
            expect { oidc_user.save }.to raise_error Gitlab::Auth::OAuth::User::SignupDisabledError # rubocop:disable Rails/SaveBang
          end
        end
      end
    end

    context 'for admin groups' do
      context 'when not defined' do
        it 'does not promote to admin' do
          oidc_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_valid
          expect(gl_user).not_to be_admin
        end

        it 'does not demote existing admin user' do
          stub_omniauth_setting(auto_link_user: true)
          create(:user, email: 'john@example.com', admin: true)
          oidc_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_valid
          expect(gl_user).to be_admin
        end
      end

      context 'when defined' do
        let(:oidc_admin_groups) { ['Administrators'] }

        context 'when user has correct admin groups membership' do
          let(:user_groups) { oidc_admin_groups }

          it 'promotes to admin' do
            oidc_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            expect(gl_user).to be_admin
          end
        end

        context 'when user is missing admin groups membership' do
          it 'does not promote to admin' do
            oidc_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            expect(gl_user).not_to be_admin
          end
        end

        context 'when user has admin and external groups membership' do
          let(:oidc_external_groups) { ['Cats'] }
          let(:user_groups) { oidc_admin_groups | oidc_external_groups }

          it 'does not promote to admin' do
            oidc_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            expect(gl_user).not_to be_admin
            expect(gl_user).to be_external
          end
        end
      end
    end

    context 'for external groups' do
      context 'when not defined' do
        it 'does not set user as external' do
          oidc_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_valid
          expect(gl_user).not_to be_external
        end

        it 'does not demote existing external user' do
          stub_omniauth_setting(auto_link_user: true)
          create(:user, email: 'john@example.com', external: true)
          oidc_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_valid
          expect(gl_user).to be_external
        end
      end

      context 'when defined' do
        let(:oidc_external_groups) { ['Cats'] }

        context 'when user has correct external groups membership' do
          let(:user_groups) { oidc_external_groups }

          it 'promotes to admin' do
            oidc_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            expect(gl_user).to be_external
          end
        end

        context 'when user is missing external groups membership' do
          it 'does not promote to admin' do
            oidc_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            expect(gl_user).not_to be_external
          end
        end
      end
    end
  end
end
