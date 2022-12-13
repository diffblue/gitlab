# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::DestroyDismissalFeedbackService, feature_category: :vulnerability_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:vulnerability) { create(:vulnerability, project: project) }

  before(:all) do
    finding_1 = create(:vulnerabilities_finding, project: project)
    finding_2 = create(:vulnerabilities_finding, project: project)

    create(:vulnerability_feedback, project: project, category: finding_1.report_type, finding_uuid: finding_1.uuid)
    create(:vulnerability_feedback, project: project, category: finding_2.report_type, finding_uuid: finding_2.uuid)
    create(:vulnerability_feedback)

    vulnerability.findings << finding_1
    vulnerability.findings << finding_2
  end

  describe '#execute' do
    subject(:destroy_feedback) { described_class.new(user, vulnerability).execute }

    context 'without necessary permissions' do
      it 'raises `Gitlab::Access::AccessDeniedError` error' do
        expect { destroy_feedback }.to raise_error(Gitlab::Access::AccessDeniedError)
                                   .and not_change { Vulnerabilities::Feedback.count }
      end
    end

    context 'with necessary permissions' do
      before do
        project.add_developer(user)
      end

      it 'destroys the feedback records associated with the findings of the given vulnerability' do
        expect { destroy_feedback }.to change { Vulnerabilities::Feedback.count }.from(3).to(1)
      end
    end
  end
end
