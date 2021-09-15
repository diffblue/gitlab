# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmoji do
  describe '#update_elastic_associations' do
    # cannot test with issue awardable because maintain_elaticsearch_update
    # is called when the upvotes_count column on the issues table is updated
    let_it_be(:note) { create(:note) }
    let_it_be(:merge_request) { create(:merge_request) }

    context 'maintaining_elasticsearch is true' do
      before do
        allow(note).to receive(:maintaining_elasticsearch?).and_return(true)
        allow(merge_request).to receive(:maintaining_elasticsearch?).and_return(true)
      end

      it 'calls maintain_elasticsearch_update on create' do
        expect(merge_request).to receive(:maintain_elasticsearch_update)

        create(:award_emoji, :upvote, awardable: merge_request)
      end

      it 'calls maintain_elasticsearch_update on destroy' do
        award_emoji = create(:award_emoji, :upvote, awardable: merge_request)

        expect(merge_request).to receive(:maintain_elasticsearch_update)

        award_emoji.destroy!
      end

      it 'does nothing for other awardable_type' do
        expect(note).not_to receive(:maintain_elasticsearch_update)

        create(:award_emoji, :upvote, awardable: note)
      end
    end

    context 'maintaining_elasticsearch is false' do
      it 'does not call maintain_elasticsearch_update' do
        expect(merge_request).not_to receive(:maintain_elasticsearch_update)

        award_emoji = create(:award_emoji, :upvote, awardable: merge_request)

        expect(merge_request).not_to receive(:maintain_elasticsearch_update)

        award_emoji.destroy!
      end
    end
  end
end
