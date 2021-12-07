# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EpicsCountService, :use_clean_rails_memory_store_caching do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public)}
  let_it_be(:epic) { create(:epic, group: group) }

  subject { described_class.new(group, user) }

  describe '#relation_for_count' do
    context "when the user is a reporter" do
      before do
        group.add_reporter(user)
        allow(EpicsFinder).to receive(:new).and_call_original
      end

      it 'uses the EpicsFinder to scope epics' do
        expect(EpicsFinder)
          .to receive(:new)
          .with(user, group_id: group.id, state: 'opened')

        subject.count
      end
    end

    context "when there are confidential epics" do
      let_it_be(:epic) { create(:epic, :confidential, group: group) }

      context "when the user has view access to the group and its epics" do
        it "filters the count by visibility" do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_epic, group).and_return(true)

          expect(group.epics.count).to eq(2)
          expect(subject.count).to eq(1)
        end
      end
    end
  end

  it_behaves_like 'a counter caching service with threshold'
end
