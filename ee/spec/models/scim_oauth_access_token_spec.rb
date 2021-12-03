# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScimOauthAccessToken do
  describe "Associations" do
    it { is_expected.to belong_to :group }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:group) }
  end

  describe '.token_matches_for_group?' do
    it 'finds the token' do
      group = create(:group)

      scim_token = create(:scim_oauth_access_token, group: group)

      token_value = scim_token.token

      expect(described_class.token_matches_for_group?(token_value, group)).to be true
    end
  end

  describe '#token' do
    it 'generates a token on creation' do
      scim_token = described_class.create!(group: create(:group))

      expect(scim_token.token).to be_a(String)
    end
  end
end
