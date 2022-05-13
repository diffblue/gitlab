# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupGroupLink do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_group_link) { create(:group_group_link, shared_group: group, shared_with_group: create(:group)) }

  describe 'scopes' do
    describe '.in_shared_group' do
      it 'provides correct link records' do
        create(:group_group_link)

        expect(described_class.in_shared_group(group)).to match_array([group_group_link])
      end
    end

    describe '.not_in_shared_with_group' do
      it 'provides correct link records' do
        not_shared_with_group = create(:group)
        create(:group_group_link, shared_with_group: not_shared_with_group)

        expect(described_class.not_in_shared_with_group(not_shared_with_group)).to match_array([group_group_link])
      end
    end
  end
end
