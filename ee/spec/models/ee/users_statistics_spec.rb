# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersStatistics do
  let(:users_statistics) { build(:users_statistics, with_highest_role_minimal_access: 5) }

  describe '#billable' do
    it 'sums users statistics values excluding blocked users and bots' do
      expect(users_statistics.billable).to eq(74)
    end

    context 'when there is an ultimate license' do
      before do
        license = create(:license, plan: License::ULTIMATE_PLAN)
        allow(License).to receive(:current).and_return(license)
      end

      it 'excludes blocked users, bots, guest users, users without a group or project and minimal access users' do
        expect(users_statistics.billable).to eq(41)
      end
    end
  end

  describe '#active' do
    it 'includes minimal access roles' do
      expect(users_statistics.active).to eq(76)
    end
  end

  describe '#non_billable' do
    it 'sums bots and guests values' do
      expect(users_statistics.non_billable).to eq(7)
    end
  end

  describe '.create_current_stats!' do
    before do
      create(:user_highest_role, :minimal_access)

      allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
    end

    it 'includes minimal access in current statistics values' do
      expect(described_class.create_current_stats!).to have_attributes(
        with_highest_role_minimal_access: 1
      )
    end
  end
end
