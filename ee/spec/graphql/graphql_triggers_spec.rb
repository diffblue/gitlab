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
  end
end
