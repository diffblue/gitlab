# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epic::RelatedEpicLink do
  describe 'Associations' do
    it { is_expected.to belong_to(:source).class_name('Epic') }
    it { is_expected.to belong_to(:target).class_name('Epic') }
  end

  describe 'link_type' do
    it { is_expected.to define_enum_for(:link_type).with_values(relates_to: 0, blocks: 1) }

    it 'provides the "related" as default link_type' do
      expect(create(:related_epic_link).link_type).to eq 'relates_to'
    end
  end

  describe 'Validation' do
    subject { create :related_epic_link }

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:target) }
    it do
      is_expected.to validate_uniqueness_of(:source)
                       .scoped_to(:target_id)
                       .with_message(/already related/)
    end

    it 'is not valid if an opposite link already exists' do
      related_epic_link = build(:related_epic_link, source: subject.target, target: subject.source)

      expect(related_epic_link).to be_invalid
      expect(related_epic_link.errors[:source]).to include('is already related to this epic')
    end

    context 'when it relates to itself' do
      let(:epic) { create :epic }

      context 'cannot be validated' do
        it 'does not invalidate object with self relation error' do
          related_epic_link = build(:related_epic_link, source: epic, target: nil)

          related_epic_link.valid?

          expect(related_epic_link.errors[:source]).to be_empty
        end
      end

      context 'can be invalidated' do
        it 'invalidates object' do
          related_epic_link = build(:related_epic_link, source: epic, target: epic)

          expect(related_epic_link).to be_invalid
          expect(related_epic_link.errors[:source]).to include('cannot be related to itself')
        end
      end
    end
  end

  describe 'Scopes' do
    let_it_be(:epic1) { create(:epic) }
    let_it_be(:epic2) { create(:epic) }

    describe '.for_source_epic' do
      it 'includes related epics for source epic' do
        source_epic = create(:epic)
        related_epic_link_1 = create(:related_epic_link, source: source_epic, target: epic1)
        related_epic_link_2 = create(:related_epic_link, source: source_epic, target: epic2)

        result = described_class.for_source_epic(source_epic)

        expect(result).to contain_exactly(related_epic_link_1, related_epic_link_2)
      end
    end

    describe '.for_target_epic' do
      it 'includes related epics for target epic' do
        target_epic = create(:epic)
        related_epic_link_1 = create(:related_epic_link, source: epic1, target: target_epic)
        related_epic_link_2 = create(:related_epic_link, source: epic2, target: target_epic)

        result = described_class.for_target_epic(target_epic)

        expect(result).to contain_exactly(related_epic_link_1, related_epic_link_2)
      end
    end
  end
end
