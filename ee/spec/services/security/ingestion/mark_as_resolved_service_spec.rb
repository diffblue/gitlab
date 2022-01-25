# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::MarkAsResolvedService do
  let!(:project) { create(:project) }
  let!(:vulnerability_1) { create(:vulnerability, project: project) }
  let!(:vulnerability_2) { create(:vulnerability, project: project) }

  let(:ingested_ids) { [vulnerability_2.id] }
  let(:service_object) { described_class.new(project, ingested_ids) }

  describe '#execute' do
    subject(:mark_as_resolved) { service_object.execute }

    it 'marks the missing vulnerabilities as resolved on default branch' do
      expect { mark_as_resolved }.to change { vulnerability_1.reload.resolved_on_default_branch }.from(false).to(true)
                                 .and not_change { vulnerability_2.reload.resolved_on_default_branch }.from(false)
    end
  end
end
