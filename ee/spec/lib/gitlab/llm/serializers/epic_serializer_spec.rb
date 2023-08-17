# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Serializers::EpicSerializer, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:epic) { create(:epic) }
  let_it_be(:content_limit) { 1000 }
  let(:serializer_double) { instance_double(::EpicSerializer) }

  describe '.serialize' do
    subject(:serialized_epic) { described_class.serialize(epic: epic, user: user, content_limit: content_limit) }

    it 'serializes the epic and its comments' do
      expect(serialized_epic).to include(:epic_comments)
      expect(serialized_epic[:epic_comments]).to be_an(Array)
    end

    it 'calls serializer to serialize the epic' do
      expect(serializer_double).to receive(:represent).with(epic).and_return({ id: 1 })
      expect(::EpicSerializer).to receive(:new).with(current_user: user).and_return(serializer_double)

      expect(described_class.serialize(epic: epic, user: user, content_limit: content_limit)).to include(
        id: 1,
        epic_comments: []
      )
    end

    context 'when there are no notes for the epic' do
      it 'returns an empty array' do
        notes = described_class.serialize(epic: epic, user: user, content_limit: content_limit).fetch(:epic_comments)

        expect(notes).to be_an(Array)
        expect(notes).to be_empty
      end
    end

    context 'when there are notes for the epic' do
      let_it_be(:note) { create(:note, noteable: epic) }

      it 'returns an array with notes' do
        notes = described_class.serialize(epic: epic, user: user, content_limit: content_limit).fetch(:epic_comments)

        expect(notes).to contain_exactly(note.note)
      end

      context 'when there are more notes for the epic' do
        it 'returns an array with notes no longer than limit' do
          create(:note, noteable: epic, note: '*' * content_limit)

          notes = described_class.serialize(epic: epic, user: user, content_limit: content_limit)
                                 .fetch(:epic_comments)

          expect(notes).to be_an(Array)
          expect(notes).to contain_exactly(note.note)
        end
      end
    end
  end
end
