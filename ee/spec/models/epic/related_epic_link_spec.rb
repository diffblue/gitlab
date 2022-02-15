# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epic::RelatedEpicLink do
  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:related_epic_link) }
    let_it_be(:issuable) { create(:epic) }
    let(:issuable_class) { 'Epic' }
    let(:issuable_link_factory) { :related_epic_link }
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
