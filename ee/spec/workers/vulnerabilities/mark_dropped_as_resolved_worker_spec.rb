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
          .to(Users::Internal.security_bot.id)
      end

      it 'creates state transition entry with note for each vulnerability' do
        expect { subject }.to change(::Vulnerabilities::StateTransition, :count)
          .from(0)
          .to(1)
          .and change(Note, :count)
          .by(1)

        transition = ::Vulnerabilities::StateTransition.last
        expect(transition.vulnerability_id).to eq(dismissable_vulnerability.id)
        expect(transition.author_id).to eq(Users::Internal.security_bot.id)
        expect(transition.comment).to match(/automatically resolved/)
      end

      it 'includes a link to documentation on SAST rules changes' do
        expect { subject }.to change(::Vulnerabilities::StateTransition, :count)
          .from(0)
          .to(1)
          .and change(Note, :count)
          .by(1)

        transition = ::Vulnerabilities::StateTransition.last
        expect(transition.comment).to eq(
          "This vulnerability was automatically resolved because its vulnerability type was disabled in this project " \
          "or removed from GitLab's default ruleset. " \
          "For details about SAST rule changes, " \
          "see https://docs.gitlab.com/ee/user/application_security/sast/rules#important-rule-changes."
        )
      end
    end
  end
end
