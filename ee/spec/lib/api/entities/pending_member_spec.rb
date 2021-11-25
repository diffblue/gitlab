# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PendingMember do
  subject(:pending_member) { described_class.new(member).as_json }

  context 'with a user present' do
    let(:member) { create(:group_member, :awaiting) }

    it 'exposes correct attributes' do
      expect(pending_member.keys).to match_array [
        :id,
        :name,
        :username,
        :email,
        :avatar_url,
        :web_url,
        :approved,
        :invited
      ]
    end
  end

  context 'with no user present' do
    let(:member) { create(:group_member, :invited) }

    it 'exposes correct attributes' do
      expect(pending_member.keys).to match_array [
        :id,
        :email,
        :avatar_url,
        :approved,
        :invited
      ]
    end
  end
end
