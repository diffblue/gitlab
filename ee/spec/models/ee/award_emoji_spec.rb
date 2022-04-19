# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmoji do
  describe 'validations' do
    context 'custom emoji' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }
      let_it_be(:emoji) { create(:custom_emoji, name: 'partyparrot', namespace: group) }

      before do
        group.add_maintainer(user)
      end

      it 'accepts custom emoji on epic' do
        epic = create(:epic, group: group)
        new_award = build(:award_emoji, user: user, awardable: epic, name: emoji.name)

        expect(new_award).to be_valid
      end

      it 'accepts custom emoji on subgroup epic' do
        subgroup = create(:group, parent: group)
        epic = create(:epic, group: subgroup)
        new_award = build(:award_emoji, user: user, awardable: epic, name: emoji.name)

        expect(new_award).to be_valid
      end
    end
  end
end
