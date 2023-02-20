# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::MarkAsResolvedService, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    context 'when using a vulnerability scanner' do
      let(:command) { described_class.new(scanner, ingested_ids) }
      let(:ingested_ids) { [] }
      let_it_be(:scanner) { create(:vulnerabilities_scanner, project: project) }

      it 'resolves non-generic vulnerabilities detected by the scanner' do
        vulnerability = create(:vulnerability, :sast,
          project: project,
          present_on_default_branch: true,
          resolved_on_default_branch: false,
          findings: [create(:vulnerabilities_finding, project: project, scanner: scanner)]
        )

        command.execute

        expect(vulnerability.reload).to be_resolved_on_default_branch
      end

      it 'does not resolve vulnerabilities detected by a different scanner' do
        vulnerability = create(:vulnerability, :sast, project: project, present_on_default_branch: true)

        command.execute

        expect(vulnerability.reload).not_to be_resolved_on_default_branch
      end

      it 'does not resolve generic vulnerabilities' do
        vulnerability = create(:vulnerability, :generic, project: project)

        command.execute

        expect(vulnerability.reload).not_to be_resolved_on_default_branch
      end

      context 'when a vulnerability is already ingested' do
        let_it_be(:ingested_vulnerability) { create(:vulnerability, project: project) }

        before do
          ingested_ids << ingested_vulnerability.id
        end

        it 'does not resolve ingested vulnerabilities' do
          command.execute

          expect(ingested_vulnerability.reload).not_to be_resolved_on_default_branch
        end
      end
    end

    context 'when a scanner is not available' do
      let(:command) { described_class.new(nil, []) }

      it 'does not resolve any vulnerabilities' do
        vulnerability = create(:vulnerability, :sast,
          project: project,
          present_on_default_branch: true,
          resolved_on_default_branch: false,
          findings: []
        )

        command.execute

        expect(vulnerability.reload).not_to be_resolved_on_default_branch
      end
    end
  end
end
