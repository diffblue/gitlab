# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::IdentityLinker do
  let(:user) { create(:user) }
  let(:in_response_to) { '12345' }
  let(:saml_response) { instance_double(OneLogin::RubySaml::Response, in_response_to: in_response_to) }
  let(:session) { { 'last_authn_request_id' => in_response_to } }

  let(:oauth) do
    OmniAuth::AuthHash.new(provider: 'saml', uid: user.email, extra: { response_object: saml_response })
  end

  subject(:linker) { described_class.new(user, oauth, session) }

  it 'updates membership' do
    expect(Gitlab::Auth::Saml::MembershipUpdater).to receive(:new).with(user, any_args).and_call_original

    linker.link
  end
end
