# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::NamesSuggestions::Generator do
  include UsageDataHelpers

  before do
    stub_usage_data_connections
  end

  describe '#generate' do
    shared_examples 'name suggestion' do
      it 'returns correct name' do
        expect(described_class.generate(key_path)).to match name_suggestion
      end
    end

    describe 'metrics with `having` keyword' do
      it_behaves_like 'name suggestion' do
        let(:key_path) do
          'usage_activity_by_stage_monthly.create.approval_project_rules_with_more_approvers_than_required'
        end

        let(:name_suggestion) { /\(\(COUNT\(approval_project_rules_users\) > approvals_required\)\)/ }
      end

      it_behaves_like 'name suggestion' do
        let(:key_path) do
          'usage_activity_by_stage_monthly.create.approval_project_rules_with_less_approvers_than_required'
        end

        let(:name_suggestion) { /\(\(COUNT\(approval_project_rules_users\) < approvals_required\)\)/ }
      end
    end
  end
end
