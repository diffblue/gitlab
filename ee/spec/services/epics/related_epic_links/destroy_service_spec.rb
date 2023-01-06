# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicLinks::DestroyService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let!(:issuable_link) { create(:related_epic_link) }

    before do
      stub_licensed_features(epics: true, related_epics: true)
    end

    subject { described_class.new(issuable_link, issuable_link.source, user).execute }

    it_behaves_like 'a destroyable issuable link', required_role: :guest

    context 'event tracking' do
      subject { described_class.new(issuable_link, epic, user).execute }

      let(:issuable_link) { create(:related_epic_link, link_type: link_type ) }

      before do
        issuable_link.source.resource_parent.add_guest(user)
        issuable_link.target.resource_parent.add_guest(user)
      end

      shared_examples 'a recorded event' do
        it 'records event for destroyed link' do
          expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
            .to receive(tracking_method).with(author: user, namespace: epic.group).once

          subject
        end

        context 'when given epic is not link target or source' do
          it 'does not record any event' do
            service = described_class.new(issuable_link, create(:epic), user)

            expect(service).not_to receive(:track_related_epics_event_for)

            service.execute
          end
        end
      end

      context 'for relates_to link type' do
        let(:link_type) { IssuableLink::TYPE_RELATES_TO }

        # For TYPE_RELATES_TO we record the same event when epic is link.target or link.source
        # because there is no inverse relationship.
        let(:tracking_method) { :track_linked_epic_with_type_relates_to_removed }

        context 'when epic in context is the link source' do
          let(:epic) { issuable_link.source }

          it_behaves_like 'a recorded event'
        end

        context 'when epic in context is the link target' do
          let(:epic) { issuable_link.target }

          it_behaves_like 'a recorded event'
        end
      end

      context 'for blocks link type' do
        let(:link_type) { IssuableLink::TYPE_BLOCKS }

        context 'when epic in context is the link source' do
          let(:tracking_method) { :track_linked_epic_with_type_blocks_removed }
          let(:epic) { issuable_link.source }

          it_behaves_like 'a recorded event'
        end

        context 'when epic in context is the link target' do
          let(:tracking_method) { :track_linked_epic_with_type_is_blocked_by_removed }
          let(:epic) { issuable_link.target }

          it_behaves_like 'a recorded event'
        end
      end
    end
  end
end
