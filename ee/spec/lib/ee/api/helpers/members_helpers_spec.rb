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
end
