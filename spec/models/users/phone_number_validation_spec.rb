# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::PhoneNumberValidation do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:banned_user) }

  it { is_expected.to validate_presence_of(:country) }
  it { is_expected.to validate_length_of(:country).is_at_most(3) }

  it { is_expected.to validate_presence_of(:international_dial_code) }
  it { is_expected.to validate_numericality_of(:international_dial_code).is_greater_than(0) }

  it { is_expected.to validate_presence_of(:phone_number) }
  it { is_expected.to validate_length_of(:phone_number).is_at_most(32) }

  it { is_expected.to validate_length_of(:telesign_reference_xid).is_at_most(255) }

  describe '.scopes' do
    describe '.is_related_to_banned_user?' do
      let_it_be(:international_dial_code) { 1 }
      let_it_be(:phone_number) { '555' }

      let_it_be(:user) { create(:user) }
      let_it_be(:banned_user) { create(:user, :banned) }

      subject(:is_related_to_banned_user?) do
        ::Users::PhoneNumberValidation.is_related_to_banned_user?(international_dial_code, phone_number)
      end

      context 'when banned user has the same international dial code and phone number' do
        let(:match) { create(:phone_number_validation, user: banned_user) }

        it 'returns matches' do
          expect(subject).to match_array([match])
        end
      end

      context 'when banned user has the same international dial code and phone number, but different country code' do
        let(:match) { create(:phone_number_validation, user: banned_user, country: 'CA') }

        it 'returns matches' do
          expect(subject).to match_array([match])
        end
      end

      context 'when banned user does not have the same international dial code' do
        let(:match) { create(:phone_number_validation, user: banned_user, international_dial_code: 61) }

        it 'returns empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when banned user does not have the same phone number' do
        let(:match) { create(:phone_number_validation, user: banned_user, phone_number: '666') }

        it 'returns empty array' do
          expect(subject).to be_empty
        end
      end

      context 'when not-banned user has the same international dial code and phone number' do
        let(:match) { create(:phone_number_validation, user: user) }

        it 'returns empty array' do
          expect(subject).to be_empty
        end
      end
    end
  end
end
