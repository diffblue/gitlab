# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::Minutes::RefreshCachedDataService, feature_category: :continuous_integration do
  include AfterNextHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:root_namespace) { group }
  let_it_be(:build_1) { create(:ci_build, :pending, project: project_1) }
  let_it_be(:build_2) { create(:ci_build, :pending) }
  let_it_be(:pending_build_1) { create(:ci_pending_build, build: build_1, project: build_1.project, minutes_exceeded: true) }
  let_it_be(:pending_build_2) { create(:ci_pending_build, build: build_2, project: build_2.project, minutes_exceeded: true) }

  describe '#execute' do
    subject { described_class.new(root_namespace).execute }

    context 'when root_namespace is nil' do
      let(:root_namespace) { nil }

      it 'does nothing' do
        expect { subject }.not_to raise_error

        expect_next(::Gitlab::Ci::Minutes::CachedQuota).not_to receive(:expire!)

        expect(pending_build_1.reload.minutes_exceeded).to be_truthy
        expect(pending_build_2.reload.minutes_exceeded).to be_truthy
      end
    end

    context 'when user purchases more ci minutes for a given namespace' do
      before do
        allow_next_instance_of(::Ci::Minutes::Usage) do |instance|
          allow(instance).to receive(:minutes_used_up?).and_return(false)
        end
      end

      it 'updates relevant pending builds' do
        subject

        expect(pending_build_1.reload.minutes_exceeded).to be_falsey
        expect(pending_build_2.reload.minutes_exceeded).to be_truthy
      end

      context 'when running multiple updates' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it 'runs 2 SQL update queries' do
          sql_queries = ActiveRecord::QueryRecorder.new { subject }.log
          update_queries_number = sql_queries.inject(0) do |result, query|
            result += 1 if query.start_with?("UPDATE")
            result
          end

          expect(update_queries_number).to eq(2)
          expect(pending_build_1.reload.minutes_exceeded).to be_falsey
          expect(pending_build_2.reload.minutes_exceeded).to be_truthy
        end
      end

      it 'expires the CachedQuota' do
        expect_next(::Gitlab::Ci::Minutes::CachedQuota).to receive(:expire!)

        subject
      end
    end
  end
end
