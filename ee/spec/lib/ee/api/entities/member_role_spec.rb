# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::API::Entities::MemberRole do
  describe 'exposes expected fields' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    let(:member_role) { create(:member_role) }
    let(:entity) { described_class.new(member_role) }

    subject { entity.as_json }

    it 'exposes the attributes' do
      group.add_owner(user)

      expect(subject[:id]).to eq member_role.id
      expect(subject[:base_access_level]).to eq member_role.base_access_level
      expect(subject[:read_code]).to eq member_role.read_code
      expect(subject[:group_id]).to eq(member_role.namespace.id)
    end
  end
end
