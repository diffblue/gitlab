# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::UsersFinder do
  let(:current_user) { create(:user) }
  let(:group) { create(:group) }
  let(:saml_provider) { create(:saml_provider, group: group) }

  it 'returns only users with that SAML provider when saml_provider_id is given' do
    user1 = create(:user, username: 'samdoe')
    user2 = create(:user, username: 'allymolly')
    create(:identity, saml_provider: saml_provider, user: user1)
    params = { saml_provider_id: saml_provider.id }
    group.add_members([user1, user2], GroupMember::DEVELOPER)

    users = described_class.new(params: params, current_user: current_user, project: nil, group: nil).execute.to_a

    expect(users).to match_array([user1])
  end

  it 'returns the user that name matches the search' do
    user1 = create(:user, username: 'samdoe')
    user2 = create(:user, username: 'allymolly')
    user3 = create(:user, username: 'Samamntha')
    create(:identity, saml_provider: saml_provider, user: user1)
    create(:identity, saml_provider: saml_provider, user: user2)
    create(:identity, saml_provider: saml_provider, user: user3)
    params = { saml_provider_id: saml_provider.id, search: 'sam' }
    group.add_members([user1, user2, user3], GroupMember::DEVELOPER)

    users = described_class.new(params: params, current_user: current_user, project: nil, group: nil).execute.to_a
    expect(users).to match_array([user1, user3])
  end
end
