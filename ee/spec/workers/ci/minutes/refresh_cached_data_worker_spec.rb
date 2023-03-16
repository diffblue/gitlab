# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::RefreshCachedDataWorker, feature_category: :continuous_integration do
  describe '#perform' do
    context 'when namespace is out of CI minutes' do
      include_examples 'an idempotent worker' do
        let_it_be(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
        let_it_be_with_reload(:pending_build) { create(:ci_pending_build, minutes_exceeded: false, namespace: namespace) }
        let(:job_args) { namespace.id }

        it 'updates pending builds' do
          subject

          expect(pending_build.minutes_exceeded).to be_truthy
        end
      end
    end

    context 'when namespace has CI minutes' do
      include_examples 'an idempotent worker' do
        let_it_be(:namespace) { create(:namespace, :with_not_used_build_minutes_limit) }
        let_it_be_with_reload(:pending_build) { create(:ci_pending_build, minutes_exceeded: true, namespace: namespace) }
        let(:job_args) { namespace.id }

        it 'updates pending builds' do
          subject

          expect(pending_build.minutes_exceeded).to be_falsey
        end
      end
    end

    context 'namespace does not exist' do
      it 'does nothing' do
        expect { described_class.new.perform(non_existing_record_id) }.not_to raise_error
      end
    end
  end
end
