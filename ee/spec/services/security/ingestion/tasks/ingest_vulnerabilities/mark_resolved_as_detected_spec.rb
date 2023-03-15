# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestVulnerabilities::MarkResolvedAsDetected, feature_category: :vulnerability_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
  let_it_be(:identifier) { create(:vulnerabilities_identifier) }

  let_it_be(:existing_vulnerability) do
    create(:vulnerability, :detected, :with_finding,
      resolved_on_default_branch: true, present_on_default_branch: false
    )
  end

  let_it_be(:resolved_vulnerability) do
    create(:vulnerability, :resolved, :with_finding,
      resolved_on_default_branch: true, present_on_default_branch: false
    )
  end

  let(:finding_maps) { create_list(:finding_map, 3) }

  subject(:mark_resolved_as_detected) { described_class.new(pipeline, finding_maps).execute }

  before do
    finding_maps.first.vulnerability_id = existing_vulnerability.id
    finding_maps.second.vulnerability_id = resolved_vulnerability.id

    finding_maps.each { |finding_map| finding_map.identifier_ids << identifier.id }
  end

  it 'changes state of resolved Vulnerabilities back to detected' do
    expect { mark_resolved_as_detected }.to change { resolved_vulnerability.reload.state }
      .from("resolved")
      .to("detected")
      .and not_change { existing_vulnerability.reload.state }
      .from("detected")
  end

  it 'creates state transition entry for each vulnerability' do
    expect { mark_resolved_as_detected }.to change { ::Vulnerabilities::StateTransition.count }
      .from(0)
      .to(1)
    expect(::Vulnerabilities::StateTransition.last.vulnerability_id).to eq(resolved_vulnerability.id)
  end
end
