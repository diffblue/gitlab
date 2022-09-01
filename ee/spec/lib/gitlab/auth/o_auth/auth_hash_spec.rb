# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::AuthHash do
  let(:auth_hash) do
    described_class.new(
      OmniAuth::AuthHash.new(
        provider: ascii('kerberos'),
        uid: ascii(uid),
        info: { uid: ascii(uid) }
      )
    )
  end

  describe '#uid' do
    subject { auth_hash.uid }

    context 'contains a kerberos realm' do
      let(:uid) { 'mylogin@BAR.COM' }

      it 'preserves the canonical uid' do
        is_expected.to eq('mylogin@BAR.COM')
      end
    end

    context 'does not contain a kerberos realm' do
      let(:uid) { 'mylogin' }

      before do
        allow(Gitlab::Kerberos::Authentication).to receive(:kerberos_default_realm).and_return('FOO.COM')
      end

      it 'canonicalizes uid with kerberos realm' do
        is_expected.to eq('mylogin@FOO.COM')
      end
    end
  end

  describe '#password' do
    let(:auth_hash) { described_class.new(nil) }

    context 'when password complexity feature is available' do
      before do
        stub_licensed_features(password_complexity: true)
      end

      context 'with password complexity enabled' do
        include_context 'with all password complexity rules enabled'

        let(:user) { build(:user) }

        it 'returns a valid password' do
          user.password = '12345678*a'
          expect(user).not_to be_valid

          user.password = auth_hash.password
          expect(user).to be_valid
        end
      end
    end
  end

  def ascii(text)
    text.dup.force_encoding(Encoding::ASCII_8BIT)
  end
end
