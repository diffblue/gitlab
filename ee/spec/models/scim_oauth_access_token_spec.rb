# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScimOauthAccessToken, feature_category: :system_access do
  describe "Associations" do
    it { is_expected.to belong_to :group }
  end

  describe '.token_matches_for_group?' do
    context 'when token passed in found in database' do
      context 'when token associated with group passed in' do
        it 'returns true' do
          group = create(:group)
          scim_token = create(:scim_oauth_access_token, group: group)
          token_value = scim_token.token

          expect(
            described_class.token_matches_for_group?(token_value, group)
          ).to eq true
        end
      end

      context 'when token not associated with group passed in' do
        it 'returns false' do
          other_group = create(:group)
          scim_token = create(:scim_oauth_access_token, group: create(:group))
          token_value = scim_token.token

          expect(
            described_class.token_matches_for_group?(token_value, other_group)
          ).to eq false
        end
      end
    end

    context 'when token passed in is not found in database' do
      it 'returns nil' do
        group = create(:group)

        expect(
          described_class.token_matches_for_group?('notatoken', group)
        ).to eq nil
      end
    end
  end

  describe '.token_matches_for_instance?' do
    context 'when token passed in found in database' do
      context 'when token not associated with a group' do
        it 'returns true' do
          scim_token = create(:scim_oauth_access_token, group: nil)
          token_value = scim_token.token

          expect(described_class.token_matches_for_instance?(token_value)).to eq true
        end
      end

      context 'when token associated with a group' do
        it 'returns false' do
          scim_token = create(:scim_oauth_access_token, group: create(:group))
          token_value = scim_token.token

          expect(described_class.token_matches_for_instance?(token_value)).to eq false
        end
      end
    end

    context 'when token passed in not found in database' do
      it 'returns nil' do
        expect(described_class.token_matches_for_instance?('notatoken')).to eq nil
      end
    end
  end

  describe '.find_for_instance' do
    let!(:scim_token) { create(:scim_oauth_access_token, group: nil) }

    it 'find a token with group id nil' do
      expect(described_class.find_for_instance).to eq(scim_token)
    end
  end

  describe '#token' do
    it 'generates a token on creation' do
      scim_token = described_class.create!(group: create(:group))

      expect(scim_token.token).to be_a(String)
    end

    it 'generates a token on creation without group' do
      scim_token = described_class.create!

      expect(scim_token.token).to be_a(String)
    end
  end
end
