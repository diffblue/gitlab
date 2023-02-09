# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::Detail, type: :model, feature_category: :experimentation_conversion, ee: true do
  context 'with scopes' do
    def set_schedule(group, time, notified_at = nil)
      group.namespace_details.update! next_over_limit_check_at: time, free_user_cap_over_limit_notified_at: notified_at
    end

    let_it_be(:group_1) { create :group, :private }
    let_it_be(:group_2) { create :group, :private }
    let_it_be(:group_3) { create :group, :private }
    let_it_be(:group_4) { create :group, :private }
    let_it_be(:group_5) { create :group, :private }

    let(:scheduled_items) do
      [
        group_1.namespace_details,
        group_2.namespace_details,
        group_3.namespace_details,
        group_5.namespace_details
      ]
    end

    let(:not_notified_items) do
      [
        group_1.namespace_details,
        group_2.namespace_details,
        group_3.namespace_details,
        group_4.namespace_details
      ]
    end

    let(:namespace_ids) { ::Namespaces::FreeUserCap::EnforceableGroupsFinder.new.execute.select(:id) }

    before do
      set_schedule group_1, nil
      set_schedule group_2, 2.days.ago
      set_schedule group_3, 1.5.days.ago

      set_schedule group_4, 3.days.from_now # not scheduled_item: next_over_limit_check_at too new
      set_schedule group_5, 1.day.ago, 2.days.ago # not not_notified_items: has already been notified
    end

    context 'for not_over_limit_notified' do
      it 'returns only entries that have not been notified of being over limit' do
        expect(described_class.not_over_limit_notified).to match_array(not_notified_items)
      end
    end

    context 'for scheduled_for_over_limit_check' do
      it 'returns entries that have been scheduled for over limit checks' do
        expect(described_class.scheduled_for_over_limit_check).to eq(scheduled_items)
      end
    end

    context 'for lock_for_over_limit_check' do
      let(:limit) { 2 }
      let(:scheduled_items) { [group_1.namespace_details, group_2.namespace_details] }

      subject(:lock_scope_result) { described_class.lock_for_over_limit_check(limit, namespace_ids) }

      it 'only returns scheduled entries up to the limit' do
        expect(lock_scope_result).to eq(scheduled_items)
      end
    end
  end
end
