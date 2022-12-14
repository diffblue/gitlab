# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::ScheduleMarkDroppedAsResolvedService do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
  let_it_be(:existing_identifier) { create(:vulnerabilities_identifier) }

  let_it_be(:dismissed_identifier) do
    create(:vulnerabilities_identifier, external_type: 'find_sec_bugs_type', external_id: 'PREDICTABLE_RANDOM')
  end

  let_it_be(:dropped_identifier) do
    create(:vulnerabilities_identifier, external_type: 'find_sec_bugs_type', external_id: 'OLD_PREDICTABLE_RANDOM')
  end

  before_all do
    existing_finding = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: existing_identifier.id, identifiers: [existing_identifier]
    )
    create(:vulnerability, :detected, project_id: pipeline.project_id).tap do |vuln|
      existing_finding.update!(vulnerability_id: vuln.id)
    end

    dismissed_finding = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dismissed_identifier.id,
      identifiers: [dismissed_identifier]
    )
    create(:vulnerability, :dismissed, resolved_on_default_branch: true, project_id: pipeline.project_id).tap do |vuln|
      dismissed_finding.update!(vulnerability_id: vuln.id)
    end

    untriaged_finding = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dismissed_identifier.id,
      identifiers: [dismissed_identifier]
    )
    create(:vulnerability, :detected, project_id: pipeline.project_id).tap do |vuln|
      untriaged_finding.update!(vulnerability_id: vuln.id)
    end

    dropped_finding1 = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dropped_identifier.id, identifiers: [dropped_identifier]
    )
    create(:vulnerability, :detected, resolved_on_default_branch: true, project_id: pipeline.project_id).tap do |vuln|
      dropped_finding1.update!(vulnerability_id: vuln.id)
    end

    dropped_finding2 = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dropped_identifier.id, identifiers: [dropped_identifier]
    )
    create(:vulnerability, :detected, resolved_on_default_branch: true, project_id: pipeline.project_id).tap do |vuln|
      dropped_finding2.update!(vulnerability_id: vuln.id)
    end
  end

  subject(:service) { described_class.new(pipeline.project_id, [existing_identifier]).execute }

  context 'when flag is enabled' do
    before do
      stub_feature_flags(sec_mark_dropped_findings_as_resolved: true)
    end

    it 'schedules MarkDroppedAsResolvedWorker' do
      expect { service }.to change { ::Vulnerabilities::MarkDroppedAsResolvedWorker.jobs.count }.by(1)

      expect(
        ::Vulnerabilities::MarkDroppedAsResolvedWorker.jobs.last['args']
      ).to eq([pipeline.project_id, [dropped_identifier.id]])
    end

    context 'when primary_identifiers is empty' do
      subject(:service) { described_class.new(pipeline.project_id, []).execute }

      it 'wont schedule MarkDroppedAsResolvedWorker' do
        expect { service }.to change { ::Vulnerabilities::MarkDroppedAsResolvedWorker.jobs.count }.by(0)
      end
    end
  end

  context 'when flag is disabled' do
    before do
      stub_feature_flags(sec_mark_dropped_findings_as_resolved: false)
    end

    it 'wont schedule MarkDroppedAsResolvedWorker' do
      expect { service }.to change { ::Vulnerabilities::MarkDroppedAsResolvedWorker.jobs.count }.by(0)
    end
  end
end
