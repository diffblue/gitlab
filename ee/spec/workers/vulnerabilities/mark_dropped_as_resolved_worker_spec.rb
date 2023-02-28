# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::MarkDroppedAsResolvedWorker, feature_category: :vulnerability_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
  let_it_be(:dropped_identifier) do
    create(:vulnerabilities_identifier, external_type: 'find_sec_bugs_type', external_id: 'PREDICTABLE_RANDOM')
  end

  let_it_be(:dismissable_vulnerability) do
    finding = create(
      :vulnerabilities_finding,
      project_id: pipeline.project_id, primary_identifier_id: dropped_identifier.id, identifiers: [dropped_identifier]
    )

    create(:vulnerability, :detected, resolved_on_default_branch: true, project_id: pipeline.project_id).tap do |vuln|
      finding.update!(vulnerability_id: vuln.id)
    end
  end

  describe "#perform" do
    include_examples 'an idempotent worker' do
      let(:subject) { described_class.new.perform(pipeline.project_id, [dropped_identifier.id]) }

      it 'changes state of Vulnerabilities to resolved' do
        expect { subject }.to change { dismissable_vulnerability.reload.state }
          .from('detected')
          .to('resolved')
          .and change { dismissable_vulnerability.reload.resolved_by_id }
          .from(nil)
          .to(User.security_bot.id)
      end

      it 'creates state transition entry with note for each vulnerability' do
        expect { subject }.to change(::Vulnerabilities::StateTransition, :count)
          .from(0)
          .to(1)
          .and change(Note, :count)
          .by(1)

        transition = ::Vulnerabilities::StateTransition.last
        expect(transition.vulnerability_id).to eq(dismissable_vulnerability.id)
        expect(transition.author_id).to eq(User.security_bot.id)
        expect(transition.comment).to match(/automatically resolved/)
      end

      context 'when flag is disabled' do
        before do
          stub_feature_flags(sec_mark_dropped_findings_as_resolved: false)
        end

        it 'wont change state of Vulnerabilities to resolved' do
          expect { subject }.not_to change { dismissable_vulnerability.reload.state }
        end
      end
    end
  end
end
