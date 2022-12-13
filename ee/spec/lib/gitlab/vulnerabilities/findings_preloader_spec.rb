# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Vulnerabilities::FindingsPreloader, feature_category: :vulnerability_management do
  describe '.preload!' do
    def preloaded_findings
      Gitlab::Vulnerabilities::FindingsPreloader.preload!(Vulnerabilities::Finding.all)
    end

    it 'does not preload data if not called' do
      create(:vulnerabilities_finding, scanner: create(:vulnerabilities_scanner))
      control = ActiveRecord::QueryRecorder.new { Vulnerabilities::Finding.all.map(&:scanner) }.count

      create_list(:vulnerabilities_finding, 2, scanner: create(:vulnerabilities_scanner))
      expect { Vulnerabilities::Finding.all.map(&:scanner) }.to exceed_query_limit(control)
    end

    it 'preloads scanner data' do
      create(:vulnerabilities_finding, scanner: create(:vulnerabilities_scanner))
      control = ActiveRecord::QueryRecorder.new { preloaded_findings.map(&:scanner) }.count

      create_list(:vulnerabilities_finding, 2, scanner: create(:vulnerabilities_scanner))
      expect { preloaded_findings.map(&:scanner) }.not_to exceed_query_limit(control)
    end

    it 'preloads identifier data' do
      create(:vulnerabilities_finding, identifiers: [create(:vulnerabilities_identifier)])
      control = ActiveRecord::QueryRecorder.new { preloaded_findings.map(&:identifiers) }.count

      create_list(:vulnerabilities_finding, 2, identifiers: [create(:vulnerabilities_identifier)])
      expect { preloaded_findings.map(&:identifiers) }.not_to exceed_query_limit(control)
    end

    it 'preloads project data' do
      create(:vulnerabilities_finding, project: create(:project))
      control = ActiveRecord::QueryRecorder.new { preloaded_findings.map(&:project) }.count

      create_list(:vulnerabilities_finding, 2, project: create(:project))
      expect { preloaded_findings.map(&:project) }.not_to exceed_query_limit(control)
    end

    it 'calls .preload_feedback!' do
      create_list(:vulnerabilities_finding, 2, project: create(:project))
      expect(described_class).to receive(:preload_feedback!)
      preloaded_findings
    end
  end

  describe '.preload_feedback!' do
    let(:project) { create(:project) }

    def preloaded_feedback
      findings = Vulnerabilities::Finding.all
      Gitlab::Vulnerabilities::FindingsPreloader.preload_feedback!(findings)
      findings
    end

    it 'preloads project data' do
      feedback_type = 'dismissal'
      create(:vulnerabilities_finding, project: project)
      create(:vulnerability_feedback, project: project, feedback_type: feedback_type)
      control = ActiveRecord::QueryRecorder.new do
        preloaded_feedback.map { |f| f.feedback(feedback_type: feedback_type) }
      end.count

      create_list(:vulnerabilities_finding, 2, project: project)
      create_list(:vulnerability_feedback, 2, project: project, feedback_type: feedback_type)
      expect do
        preloaded_feedback.map { |f| f.feedback(feedback_type: feedback_type) }
      end.not_to exceed_query_limit(control)
    end
  end
end
