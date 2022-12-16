# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::ScheduleMarkDroppedAsResolvedService do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
  let_it_be(:other_id) { create(:vulnerabilities_identifier) }
  let_it_be(:untriaged_id) { create(:vulnerabilities_identifier) }

  let_it_be(:dismissed_id) do
    create(:vulnerabilities_identifier, external_type: 'find_sec_bugs_type', external_id: 'PREDICTABLE_RANDOM')
  end

  let_it_be(:dropped_id) do
    create(:vulnerabilities_identifier, external_type: 'find_sec_bugs_type', external_id: 'OLD_PREDICTABLE_RANDOM')
  end

  before_all do
    # To remain untriaged (different scan_type)
    other_finding = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: other_id.id, identifiers: [other_id]
    )
    create(
      :vulnerability,
      :detected, report_type: :dast, resolved_on_default_branch: true, project_id: pipeline.project_id
    ).tap do |vuln|
      other_finding.update!(vulnerability_id: vuln.id)
    end

    # To remain untriaged (same scan_type)
    untriaged_finding = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: untriaged_id.id, identifiers: [untriaged_id]
    )
    create(
      :vulnerability,
      :detected, report_type: :sast, project_id: pipeline.project_id
    ).tap do |vuln|
      untriaged_finding.update!(vulnerability_id: vuln.id)
    end

    # To remain dismissed (same scan_type)
    dismissed_finding = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dismissed_id.id,
      identifiers: [dismissed_id]
    )
    create(
      :vulnerability,
      :dismissed, report_type: :sast, resolved_on_default_branch: true, project_id: pipeline.project_id
    ).tap do |vuln|
      dismissed_finding.update!(vulnerability_id: vuln.id)
    end

    # To be dismissed (same scan_type)
    dropped_finding1 = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dropped_id.id, identifiers: [dropped_id]
    )
    create(
      :vulnerability,
      :detected, report_type: :sast, resolved_on_default_branch: true, project_id: pipeline.project_id
    ).tap do |vuln|
      dropped_finding1.update!(vulnerability_id: vuln.id)
    end

    # To be dismissed (same scan_type)
    dropped_finding2 = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dropped_id.id, identifiers: [dropped_id]
    )
    create(
      :vulnerability,
      :detected, report_type: :sast, resolved_on_default_branch: true, project_id: pipeline.project_id
    ).tap do |vuln|
      dropped_finding2.update!(vulnerability_id: vuln.id)
    end
  end

  subject(:service) { described_class.new(pipeline.project_id, 'sast', [untriaged_id]).execute }

  context 'when flag is enabled' do
    before do
      stub_feature_flags(sec_mark_dropped_findings_as_resolved: true)
    end

    it 'schedules MarkDroppedAsResolvedWorker' do
      expect { service }.to change { ::Vulnerabilities::MarkDroppedAsResolvedWorker.jobs.count }.by(1)

      expect(
        ::Vulnerabilities::MarkDroppedAsResolvedWorker.jobs.last['args']
      ).to eq([pipeline.project_id, [dropped_id.id]])
    end

    context 'when primary_identifiers is empty' do
      subject(:service) { described_class.new(pipeline.project_id, 'sast', []).execute }

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
