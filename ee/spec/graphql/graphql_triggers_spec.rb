# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlTriggers, feature_category: :shared do
  describe '.issuable_weight_updated' do
    let(:work_item) { create(:work_item) }

    it 'triggers the issuable_weight_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_weight_updated,
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      ::GraphqlTriggers.issuable_weight_updated(work_item)
    end

    it 'triggers the issuable_iteration_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_iteration_updated,
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      ::GraphqlTriggers.issuable_iteration_updated(work_item)
    end

    describe '.issuable_health_status_updated' do
      it 'triggers the issuable_health_status_updated subscription' do
        expect(GitlabSchema.subscriptions).to receive(:trigger).with(
          :issuable_health_status_updated,
          { issuable_id: work_item.to_gid },
          work_item
        ).and_call_original

        ::GraphqlTriggers.issuable_health_status_updated(work_item)
      end
    end

    describe '.issuable_epic_updated' do
      it 'triggers the issuable_epic_updated subscription' do
        expect(GitlabSchema.subscriptions).to receive(:trigger).with(
          :issuable_epic_updated,
          { issuable_id: work_item.to_gid },
          work_item
        )

        ::GraphqlTriggers.issuable_epic_updated(work_item)
      end
    end
  end
end
