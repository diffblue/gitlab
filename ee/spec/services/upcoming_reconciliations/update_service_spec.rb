# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpcomingReconciliations::UpdateService, feature_category: :source_code_management do
  let_it_be(:existing_upcoming_reconciliation) { create(:upcoming_reconciliation, :saas) }
  let_it_be(:namespace) { create(:namespace) }

  let(:record_to_create) do
    {
      namespace_id: namespace.id,
      next_reconciliation_date: Date.today + 4.days,
      display_alert_from: Date.today - 3.days
    }
  end

  let(:record_to_update) do
    {
      namespace_id: existing_upcoming_reconciliation.namespace_id,
      next_reconciliation_date: Date.today + 4.days,
      display_alert_from: Date.today - 3.days
    }
  end

  let(:record_invalid) do
    {
      namespace_id: namespace.id,
      next_reconciliation_date: "invalid_date",
      display_alert_from: Date.today - 3.days
    }
  end

  before do
    stub_application_setting(check_namespace_plan: true)
  end

  describe '#execute' do
    subject(:service) { described_class.new(upcoming_reconciliations) }

    shared_examples 'returns success' do
      it do
        result = service.execute

        expect(result.status).to eq(:success)
      end
    end

    shared_examples 'returns error' do
      it 'returns error with correct error message' do
        result = service.execute
        errors = Gitlab::Json.parse(result.message)

        expect(result.status).to eq(:error)
        expect(errors).to include({ namespace_id.to_s => error })
      end
    end

    shared_examples 'creates new upcoming reconciliation' do
      it 'increases upcoming_reconciliations count' do
        expect { service.execute }
          .to change { GitlabSubscriptions::UpcomingReconciliation.count }.by(1)
      end

      it 'created upcoming reconciliation matches given hash' do
        service.execute

        expect_equal(GitlabSubscriptions::UpcomingReconciliation.last, record_to_create)
      end
    end

    shared_examples 'does not increase upcoming_reconciliations count' do
      it do
        expect { service.execute }
          .not_to change { GitlabSubscriptions::UpcomingReconciliation.count }
      end
    end

    shared_examples 'updates existing upcoming reconciliation' do
      it 'updated upcoming_reconciliation matches given hash' do
        service.execute

        expect_equal(
          GitlabSubscriptions::UpcomingReconciliation.find_by_namespace_id(record_to_update[:namespace_id]),
          record_to_update)
      end
    end

    context 'when upcoming_reconciliation does not exist for given namespace' do
      let(:upcoming_reconciliations) { [record_to_create] }

      it_behaves_like 'creates new upcoming reconciliation'

      it_behaves_like 'returns success'
    end

    context 'when upcoming_reconciliation exists for given namespace' do
      let(:upcoming_reconciliations) { [record_to_update] }

      context 'for gitlab.com' do
        it_behaves_like 'updates existing upcoming reconciliation'

        it_behaves_like 'does not increase upcoming_reconciliations count'

        it_behaves_like 'returns success'
      end

      context 'for self managed' do
        let(:record_to_update) do
          {
            namespace_id: nil,
            next_reconciliation_date: Date.today + 4.days,
            display_alert_from: Date.today - 3.days
          }
        end

        before do
          stub_application_setting(check_namespace_plan: false)
          create(:upcoming_reconciliation, :self_managed)
        end

        it_behaves_like 'does not increase upcoming_reconciliations count'

        it_behaves_like 'returns error' do
          let(:namespace_id) { nil }
          let(:error) { ['Namespace has already been taken'] }
        end
      end
    end

    context 'when invalid attributes' do
      let(:upcoming_reconciliations) { [record_invalid] }

      it_behaves_like 'returns error' do
        let(:namespace_id) { record_invalid[:namespace_id] }
        let(:error) { ["Next reconciliation date can't be blank"] }
      end
    end

    context 'partial success' do
      let(:upcoming_reconciliations) { [record_to_create, record_to_update, record_invalid] }

      it_behaves_like 'creates new upcoming reconciliation'

      it_behaves_like 'updates existing upcoming reconciliation'

      it_behaves_like 'returns error' do
        let(:namespace_id) { record_invalid[:namespace_id] }
        let(:error) { ["Next reconciliation date can't be blank"] }
      end
    end

    context 'when bulk upsert failed' do
      let(:upcoming_reconciliations) { [record_to_create] }
      let(:bulk_error) { 'bulk_upsert_error' }

      before do
        expect(GitlabSubscriptions::UpcomingReconciliation)
          .to receive(:bulk_upsert!).and_raise(StandardError, bulk_error)
      end

      it 'logs bulk upsert error' do
        expect(Gitlab::AppLogger).to receive(:error).with("Upcoming reconciliations bulk_upsert error: #{bulk_error}")

        service.execute
      end

      it_behaves_like 'returns error' do
        let(:error) { bulk_error }
        let(:namespace_id) { 'bulk_upsert' }
      end
    end

    def expect_equal(upcoming_reconciliation, hash)
      aggregate_failures do
        expect(upcoming_reconciliation.namespace_id).to eq(hash[:namespace_id])
        expect(upcoming_reconciliation.next_reconciliation_date).to eq(hash[:next_reconciliation_date])
        expect(upcoming_reconciliation.display_alert_from).to eq(hash[:display_alert_from])
      end
    end
  end
end
