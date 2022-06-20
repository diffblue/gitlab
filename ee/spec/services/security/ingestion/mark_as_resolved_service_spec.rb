# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::MarkAsResolvedService do
  let!(:project) { create(:project) }
  let!(:not_ingested_vulnerability) { create(:vulnerability, project: project) }
  let!(:ingested_vulnerability) { create(:vulnerability, project: project) }
  let!(:generic_vulnerability) { create(:vulnerability, project: project, report_type: :generic) }

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
  end
end
