# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::MembershipEnforcer do
  let(:user) { create(:user) }
  let(:identity) { create(:group_saml_identity, user: user) }
  let(:group) { identity.saml_provider.group }

  before do
    allow_any_instance_of(SamlProvider).to receive(:enforced_sso?).and_return(true)
  end

  it 'allows adding a user linked to the SAML account as member' do
    expect(described_class.new(group).can_add_user?(user)).to be_truthy
  end

  it 'does not allow adding a user not linked to the SAML account as member' do
    non_saml_user = create(:user)

    expect(described_class.new(group).can_add_user?(non_saml_user)).to be_falsey
  end

  it 'allows adding a project bot as member' do
    project_bot = create(:user, :project_bot)

    expect(described_class.new(group).can_add_user?(project_bot)).to be_truthy
  end
end
