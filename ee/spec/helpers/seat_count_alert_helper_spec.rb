# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SeatCountAlertHelper, :saas do
  let(:user) { create(:user) }

  let(:seat_count_data) do
    {
      namespace: namespace,
      remaining_seat_count: 15 - 14,
      seats_in_use: 14,
      total_seat_count: 15
    }
  end

  before do
    assign(:seat_count_data, seat_count_data)

    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#remaining_seat_count' do
    let(:namespace) { create(:group) }

    it 'sets remaining seats count to the correct number' do
      expect(helper.remaining_seat_count).to eq(1)
    end
  end

  describe '#show_seat_count_alert?' do
    context 'with no seat count data' do
      let(:seat_count_data) { nil }

      it 'does not show the alert' do
        expect(helper.show_seat_count_alert?).to be false
      end
    end

    context 'with seat count data' do
      let(:namespace) { create(:group) }

      it 'does show the alert' do
        expect(helper.show_seat_count_alert?).to be true
      end
    end
  end

  describe '#total_seat_count' do
    context 'when the namespace is nil' do
      let(:seat_count_data) { { namespace: nil } }

      it 'returns nil' do
        expect(helper.total_seat_count).to be_nil
      end
    end

    context 'when the namespace is present' do
      let(:namespace) { create(:group) }

      it 'sets total seats count to the correct number' do
        expect(helper.total_seat_count).to eq(15)
      end
    end
  end
end
