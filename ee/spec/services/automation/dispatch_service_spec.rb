# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Automation::DispatchService, feature_category: :no_code_automation do
  describe '#execute' do
    let_it_be(:namespace) { create(:project_namespace) }

    let_it_be(:issue_rule) { create(:automation_rule, namespace: namespace, issues_events: true) }

    let_it_be(:mr_rule) { create(:automation_rule, namespace: namespace, merge_requests_events: true) }

    let(:data) { { info: '123' } }

    before do
      allow(Automation::ExecuteRuleWorker).to receive(:perform_async)
      described_class.new(container: namespace).execute(data, hook)
    end

    describe 'execute' do
      context 'when dispatching issue_hooks' do
        let(:hook) { :issue_hooks }

        it 'performs predefined issue rule' do
          expect(Automation::ExecuteRuleWorker).to have_received(:perform_async)
            .with(issue_rule.id)
        end
      end

      context 'when dispatching merge_request_hooks' do
        let(:hook) { :merge_request_hooks }

        it 'performs predefined issue rule' do
          expect(Automation::ExecuteRuleWorker).to have_received(:perform_async)
            .with(mr_rule.id)
        end
      end
    end
  end
end
