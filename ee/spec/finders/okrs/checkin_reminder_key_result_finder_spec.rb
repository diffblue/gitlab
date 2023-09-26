# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Okrs::CheckinReminderKeyResultFinder, feature_category: :team_planning do
  let(:finder) { described_class.new(frequency) }

  let_it_be(:frequency) { 'monthly' }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:top_level_objective1) { create(:work_item, :objective, project: project) }
  let_it_be(:sub_objective1) { create(:work_item, :objective, project: project) }
  let_it_be(:key_result1) { create(:work_item, :key_result, project: project) }
  let_it_be(:key_result2) { create(:work_item, :key_result, :closed, project: project) }
  let_it_be(:key_result3) { create(:work_item, :key_result, project: project) }
  let_it_be(:key_result4) { create(:work_item, :key_result, project: project) }

  let_it_be(:top_level_objective2) { create(:work_item, :objective, project: project) }
  let_it_be(:sub_objective2) { create(:work_item, :objective, project: project) }
  let_it_be(:key_result5) { create(:work_item, :key_result, project: project) }

  let_it_be(:top_level_objective3) { create(:work_item, :objective, project: project) }
  let_it_be(:key_result6) { create(:work_item, :key_result, project: project) }

  describe '#execute' do
    before_all do
      # top_level_objective1
      create(:parent_link, work_item_parent: top_level_objective1, work_item: sub_objective1)
      create(:parent_link, work_item_parent: sub_objective1, work_item: key_result1)
      create(:parent_link, work_item_parent: sub_objective1, work_item: key_result2)
      create(:parent_link, work_item_parent: sub_objective1, work_item: key_result3)
      create(:parent_link, work_item_parent: sub_objective1, work_item: key_result4)

      create(:progress, work_item: top_level_objective1, reminder_frequency: 'monthly')
      create(:progress, work_item: key_result1, last_reminder_sent_at: 28.days.ago)
      create(:progress, work_item: key_result2, last_reminder_sent_at: 28.days.ago)
      create(:progress, work_item: key_result3, last_reminder_sent_at: 28.days.ago)
      create(:progress, work_item: key_result4, last_reminder_sent_at: 4.days.ago)

      # top_level_objective2
      create(:parent_link, work_item_parent: top_level_objective2, work_item: sub_objective2)
      create(:parent_link, work_item_parent: sub_objective2, work_item: key_result5)
      create(:progress, work_item: top_level_objective2, reminder_frequency: 'weekly')
      create(:progress, work_item: key_result5, last_reminder_sent_at: 4.days.ago)

      # top_level_objective3
      create(:parent_link, work_item_parent: top_level_objective3, work_item: key_result6)
      create(:progress, work_item: top_level_objective3, reminder_frequency: 'monthly')
      create(:progress, work_item: key_result6, last_reminder_sent_at: 28.days.ago)

      [key_result1, key_result2, key_result4, key_result5, key_result6].each do |key_result|
        key_result.assignees = [user]
      end
    end

    subject { finder.execute }

    it 'returns an array of work items' do
      expect(subject.map(&:class)).to match_array([WorkItem, WorkItem])

      # returns only work items in the opened state
      expect(subject).to match_array([key_result1, key_result6])
      expect(subject).not_to include(key_result2)

      # returns only work items of the type key_result
      expect(subject).not_to include(sub_objective1)
      expect(subject).not_to include(sub_objective2)

      # returns only descendent work items of parent item with the given reminder frequency
      expect(subject).to match_array([key_result1, key_result6])

      # does not return descendent work items of parent item without the given reminder frequency
      expect(subject).not_to include(key_result5)

      # does not include work items that are not descendents
      expect(subject).not_to include(top_level_objective1)
      expect(subject).not_to include(top_level_objective2)
      expect(subject).not_to include(top_level_objective3)

      # does not return work items when last_reminder_sent_at is after the configured days in the past
      expect(subject).not_to include(key_result4)

      # does not return work items without assignees
      expect(subject).not_to include(key_result2)
    end
  end

  describe '#frequency_reminder_date' do
    subject { finder.send(:frequency_reminder_date) }

    using RSpec::Parameterized::TableSyntax

    where(:frequency, :expected_date) do
      'monthly' | (Date.today - 27.days)
      'twice_monthly' | (Date.today - 13.days)
      'weekly' | (Date.today - 6.days)
      'foo' | nil
    end

    with_them do
      it { is_expected.to eq(expected_date) }
    end
  end
end
