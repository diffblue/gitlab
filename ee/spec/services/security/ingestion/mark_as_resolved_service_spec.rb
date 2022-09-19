# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::MarkAsResolvedService do
  let_it_be(:project) { create(:project) }
  let_it_be(:non_default_vulnerability) { create(:vulnerability, project: project, present_on_default_branch: false) }

  let_it_be_with_reload(:not_ingested_vulnerability) { create(:vulnerability, project: project) }
  let_it_be_with_reload(:ingested_vulnerability) { create(:vulnerability, project: project) }
  let_it_be_with_reload(:generic_vulnerability) { create(:vulnerability, project: project, report_type: :generic) }

  let(:ingested_ids) { [ingested_vulnerability.id] }
  let(:service_object) { described_class.new(project, ingested_ids) }

  describe '#execute' do
    subject(:mark_as_resolved) { service_object.execute }

    it 'marks the missing vulnerabilities as resolved on default branch except the generic ones' do
      expect { mark_as_resolved }
        .to change { not_ingested_vulnerability.reload.resolved_on_default_branch }.from(false).to(true)
        .and not_change { ingested_vulnerability.reload.resolved_on_default_branch }.from(false)
        .and not_change { generic_vulnerability.reload.resolved_on_default_branch }.from(false)
    end

    it 'does not process vulnerabilities which are not present on the default branch' do
      expect(service_object).to receive(:process_batch)
        .with(match_array([not_ingested_vulnerability, ingested_vulnerability, generic_vulnerability]))

      mark_as_resolved
    end
  end
end
