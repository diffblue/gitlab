# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::BulkDismiss, feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:vulnerabilities) { create_list(:vulnerability, 2, :with_findings, project: project) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:vulnerability_ids) { vulnerabilities.map(&:to_global_id) }
  let(:comment) { 'Dismissal Feedback' }
  let(:dismissal_reason) { 'used_in_tests' }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  before_all do
    project.add_developer(user)
  end

  subject do
    mutation.resolve(
      vulnerability_ids: vulnerability_ids,
      comment: comment,
      dismissal_reason: dismissal_reason
    )
  end

  describe '#resolve' do
    it 'does not introduce N+1 errors' do
      queries = ActiveRecord::QueryRecorder.new do
        subject
      end

      expect(
        queries.occurrences_starting_with('INSERT INTO "vulnerability_state_transitions"').values.sum
      ).to eq(1)
      expect(queries.occurrences_starting_with('INSERT INTO "notes"').values.sum).to eq(1)
      expect(queries.occurrences_starting_with('SELECT "namespaces"').values.sum).to eq(2)
      expect(queries.occurrences_starting_with('SELECT "project_features"').values.sum).to eq(1)
      expect(queries.occurrences_starting_with('SELECT "vulnerabilities"').values.sum).to eq(1)
      expect(queries.occurrences_starting_with('SELECT "projects"').values.sum).to eq(1)
      expect(queries.occurrences_starting_with('UPDATE "vulnerabilities"').values.sum).to eq(1)
      expect(queries.occurrences_starting_with('UPDATE "vulnerability_reads"').values.sum).to eq(1)
      expect(queries.count).to be <= 15
    end
  end
end
