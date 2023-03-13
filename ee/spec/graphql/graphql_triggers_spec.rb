# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlTriggers do
  describe '.issuable_weight_updated' do
    let(:work_item) { create(:work_item) }

    it 'triggers the issuableWeightUpdated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableWeightUpdated',
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      ::GraphqlTriggers.issuable_weight_updated(work_item)
    end

    it 'triggers the issuableIterationUpdated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableIterationUpdated',
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      ::GraphqlTriggers.issuable_iteration_updated(work_item)
    end

    describe '.issuable_health_status_updated' do
      it 'triggers the issuableHealthStatusUpdated subscription' do
        expect(GitlabSchema.subscriptions).to receive(:trigger).with(
          'issuableHealthStatusUpdated',
          { issuable_id: work_item.to_gid },
          work_item
        ).and_call_original

        ::GraphqlTriggers.issuable_health_status_updated(work_item)
      end
    end

    describe '.issuable_epic_updated' do
      it 'triggers the issuableEpicUpdated subscription' do
        expect(GitlabSchema.subscriptions).to receive(:trigger).with(
          'issuableEpicUpdated',
          { issuable_id: work_item.to_gid },
          work_item
        )

        ::GraphqlTriggers.issuable_epic_updated(work_item)
      end

      context 'when real_time_issue_epic_links feature is disabled' do
        it 'does not trigger the issuableEpicUpdated subscription' do
          stub_feature_flags(real_time_issue_epic_links: false)

          expect(GitlabSchema.subscriptions).not_to receive(:trigger)

          ::GraphqlTriggers.issuable_epic_updated(work_item)
        end
      end
    end
  end
end
