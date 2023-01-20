# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuickActions::TargetService do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user, group: group) }

  before do
    group.add_maintainer(user)
    stub_licensed_features(epics: true)
  end

  describe '#execute' do
    context 'for epic' do
      let(:type) { 'Epic' }

      it 'finds target with valid iid' do
        epic = create(:epic, group: group)

        target = service.execute(type, epic.iid)

        expect(target).to eq(epic)
      end

      it 'builds a new target if iid from a different group passed' do
        epic = create(:epic)

        target = service.execute(type, epic.iid)

        expect(target).to be_new_record
        expect(target.group).to eq(group)
      end
    end
  end
end
