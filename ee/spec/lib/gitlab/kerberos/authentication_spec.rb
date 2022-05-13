# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kerberos::Authentication do
  before do
    described_class.krb5_class # eager load Krb5Auth::Krb5
  end

  describe '.kerberos_default_realm' do
    it "returns the default realm exposed by the Kerberos library" do
      allow_next_instance_of(::Krb5Auth::Krb5) do |instance|
        allow(instance).to receive_messages(get_default_realm: "FOO.COM")
      end

      expect(described_class.kerberos_default_realm).to eq("FOO.COM")
    end
  end
end
