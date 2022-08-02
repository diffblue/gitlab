# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::API::Helpers::MembersHelpers do
  include SortingHelper

  let(:members_helpers) { Class.new.include(described_class).new }

  before do
    allow(members_helpers).to receive(:current_user).and_return(create(:user))
  end

  describe '.member_sort_options' do
    it 'lists all keys available in group member view' do
      sort_options = %w[
        access_level_asc access_level_desc last_joined name_asc name_desc oldest_joined
        oldest_sign_in recent_sign_in last_activity_on_asc last_activity_on_desc
      ]

      expect(described_class.member_sort_options).to match_array sort_options
    end
  end

  describe '.billable_member?' do
    let_it_be(:group) { build(:group) }
    let_it_be(:user) { build(:user) }

    subject(:billable_member) { members_helpers.billable_member?(group, user) }

    before do
      expect_next_instance_of(BilledUsersFinder, group, include_awaiting_members: true) do |finder|
        expect(finder).to receive(:execute).and_return({ users: found_users })
      end
    end

    context 'when member is billable' do
      let(:found_users) { [user] }

      it { is_expected.to eq(true) }
    end

    context 'when member is not billable' do
      let(:found_users) { [] }

      it { is_expected.to eq(false) }
    end
  end
end
