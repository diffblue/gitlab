# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicLinks::DestroyService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let!(:issuable_link) { create(:related_epic_link) }

    before do
      stub_licensed_features(epics: true, related_epics: true)
    end

    subject { described_class.new(issuable_link, user).execute }

    it_behaves_like 'a destroyable issuable link'

    context 'event tracking' do
      let(:issuable_link) { create(:related_epic_link, link_type: link_type ) }

      before do
        issuable_link.source.resource_parent.add_reporter(user)
        issuable_link.target.resource_parent.add_reporter(user)
      end

      shared_examples 'a recorded event' do
        it 'records event for destroyed link' do
          expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
            .to receive(tracking_method).with(author: user).once

          subject
        end
      end

      context 'for relates_to link type' do
        let(:link_type) { IssuableLink::TYPE_RELATES_TO }
        let(:tracking_method) { :track_linked_epic_with_type_relates_to_removed }

        it_behaves_like 'a recorded event'
      end

      context 'for blocks link type' do
        let(:link_type) { IssuableLink::TYPE_BLOCKS }
        let(:tracking_method) { :track_linked_epic_with_type_blocks_removed }

        it_behaves_like 'a recorded event'
      end
    end
  end
end
