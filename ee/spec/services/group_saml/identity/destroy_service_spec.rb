# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupSaml::Identity::DestroyService, feature_category: :system_access do
  let(:identity) { create(:group_saml_identity) }

  subject { described_class.new(identity) }

  before do
    identity.saml_provider.group.add_guest(identity.user)
  end

  it "prevents future Group SAML logins" do
    subject.execute

    expect(identity).to be_destroyed
  end

  it "does not use a transaction" do
    expect(::Identity).not_to receive(:transaction)

    subject.execute
  end

  it "uses a transaction when transactional is set" do
    expect(::Identity).to receive(:transaction).and_yield.once

    subject.execute(transactional: true)
  end

  it "removes access to the group" do
    expect do
      subject.execute
    end.to change(GroupMember, :count).by(-1)
  end

  it "doesn't remove the last group owner" do
    identity.saml_provider.group.members.first.update!(access_level: Gitlab::Access::OWNER)

    expect do
      subject.execute
    end.not_to change(GroupMember, :count)
  end

  it 'logs an audit event' do
    expect do
      subject.execute
    end.to change { AuditEvent.count }.by(1)
  end
end
