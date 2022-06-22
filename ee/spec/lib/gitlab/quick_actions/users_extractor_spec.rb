# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QuickActions::UsersExtractor do
  subject(:extractor) { described_class.new(current_user, project: project, group: group, target: target, text: text) }

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target) { create(:issue, project: project) }

  let_it_be(:pancakes) { create(:user, username: 'pancakes') }
  let_it_be(:waffles) { create(:user, username: 'waffles') }
  let_it_be(:syrup) { create(:user, username: 'syrup') }

  context 'when looking for group members' do
    let_it_be(:group) { create(:group, path: 'breakfast-foods') }

    let(:text) { "me and #{group.to_reference}" }

    before do
      [pancakes, waffles].each { group.add_developer(_1) }
    end

    it 'finds the group members' do
      expect(extractor.execute).to contain_exactly(current_user, pancakes, waffles)
    end

    context 'when we do not find a group' do
      let(:text) { "me and #{group.to_reference} and @healthy-food" }

      it 'complains' do
        expect { extractor.execute }.to raise_error(described_class::MissingError, include('healthy-food'))
      end
    end
  end
end
