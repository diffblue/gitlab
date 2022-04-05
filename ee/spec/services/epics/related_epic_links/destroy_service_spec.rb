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
      before do
        issuable_link.source.resource_parent.add_reporter(user)
        issuable_link.target.resource_parent.add_reporter(user)
      end

      context 'for relates_to link type' do
        it 'records event for related epic link destroyed' do
          expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
            .to receive(:track_linked_epic_with_type_relates_to_removed).with(author: user).once

          subject
        end
      end
    end
  end
end
