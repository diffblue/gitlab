# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Participable do
  context 'participable is an epic' do
    let(:model) { Epic }
    let(:instance) { model.new }

    let(:user1) { build(:user) }
    let(:user2) { build(:user) }
    let(:user3) { build(:user) }
    let(:group) { build(:group, :public) }

    before do
      allow(model).to receive(:participant_attrs).and_return([:foo, :bar])
    end

    describe '#participants' do
      it 'returns the list of participants' do
        expect(instance).to receive(:foo).and_return(user2)
        expect(instance).to receive(:bar).and_return(user3)
        expect(instance).to receive(:group).thrice.and_return(group)

        participants = instance.participants(user1)
        expect(participants).to contain_exactly(user2, user3)
      end
    end

    describe '#participant?' do
      it 'returns whether the user is a participant' do
        allow(instance).to receive(:foo).and_return(user2)
        allow(instance).to receive(:bar).and_return(user3)
        allow(instance).to receive(:group).and_return(group)

        expect(instance.participant?(user1)).to be false
        expect(instance.participant?(user2)).to be true
        expect(instance.participant?(user3)).to be true
      end
    end

    describe '#visible_participants' do
      it_behaves_like 'visible participants for issuable with read ability', :epic
    end
  end
end
