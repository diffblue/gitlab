# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Ldap::User do
  include LdapHelpers

  let(:ldap_user) { described_class.new(auth_hash) }
  let(:gl_user) { ldap_user.gl_user }
  let(:info) do
    {
      name: 'John',
      email: 'john@example.com',
      nickname: 'john'
    }
  end

  let(:auth_hash) do
    OmniAuth::AuthHash.new(uid: 'uid=john,ou=people,dc=example,dc=com', provider: 'ldapmain', info: info)
  end

  let(:group_cn) { 'foo' }
  let(:group_member_dns) { [auth_hash.uid] }
  let(:external_groups) { [] }
  let!(:fake_proxy) { fake_ldap_sync_proxy(auth_hash.provider) }

  before do
    allow(fake_proxy).to receive(:dns_for_group_cn).with(group_cn).and_return(group_member_dns)
    stub_ldap_config(external_groups: external_groups)
    stub_ldap_setting(enabled: true)
  end

  it 'includes the EE module' do
    expect(described_class).to include_module(EE::Gitlab::Auth::Ldap::User)
  end

  describe '#initialize' do
    context 'when there is one external group' do
      let(:external_groups) { [group_cn] }

      context 'when there is another user in the external group' do
        context 'when the user is in the external group' do
          let(:group_member_dns) { ['uid=someone_else,ou=people,dc=example,dc=com', auth_hash.uid] }

          it "sets the user's external flag to true" do
            expect(gl_user.external).to be_truthy
          end
        end

        context 'when the user is not in the external group' do
          let(:group_member_dns) { ['uid=someone_else,ou=people,dc=example,dc=com'] }

          it "sets the user's external flag to false" do
            expect(gl_user.external).to be_falsey
          end
        end
      end

      context 'when there are no other users in the external group' do
        context 'when the user is in the external group' do
          let(:group_member_dns) { [auth_hash.uid] }

          it "sets the user's external flag to true" do
            expect(gl_user.external).to be_truthy
          end
        end

        context 'when the user is not in the external group' do
          let(:group_member_dns) { [] }

          it "sets the user's external flag to false" do
            expect(gl_user.external).to be_falsey
          end
        end
      end

      context 'with "user_default_external" application setting' do
        using RSpec::Parameterized::TableSyntax

        where(:user_default_external, :user_default_internal_regex, :user_is_in_external_group, :expected_to_be_external) do
          true  | nil           | false | false
          true  | 'example.com' | false | false

          true  | nil           | true | true
          true  | 'example.com' | true | true

          false | nil           | false | false
          false | 'example.com' | false | false

          false | nil           | true | true
          false | 'example.com' | true | true
        end

        with_them do
          let(:group_member_dns) { ['uid=someone_else,ou=people,dc=example,dc=com', user_is_in_external_group ? auth_hash.uid : nil].compact }

          before do
            stub_application_setting(user_default_external: user_default_external)
            stub_application_setting(user_default_internal_regex: user_default_internal_regex)
          end

          it "sets the user's external flag appropriately" do
            expect(gl_user.external).to eq(expected_to_be_external)
          end
        end
      end
    end

    context 'when there is more than one external group' do
      let(:external_groups) { ['bar', group_cn] }

      before do
        allow(fake_proxy).to receive(:dns_for_group_cn).with('bar').and_return(['uid=someone_else,ou=people,dc=example,dc=com'])
      end

      context 'when the user is in an external group' do
        let(:group_member_dns) { [auth_hash.uid] }

        it "sets the user's external flag to true" do
          expect(gl_user.external).to be_truthy
        end
      end

      context 'when the user is not in an external group' do
        let(:group_member_dns) { [] }

        it "sets the user's external flag to false" do
          expect(gl_user.external).to be_falsey
        end
      end
    end

    context 'when there are no external groups' do
      let(:external_groups) { [] }

      it "sets the user's external flag to false" do
        expect(gl_user.external).to be_falsey
      end

      context 'when the user_default_external application setting is true' do
        it 'does not set the external flag to false' do
          stub_application_setting(user_default_external: true)

          expect(gl_user.external).to be_truthy
        end
      end
    end
  end

  describe '#find_user' do
    it_behaves_like 'finding user when user cap is set' do
      let(:o_auth_user) { ldap_user }
    end
  end
end
