# frozen_string_literal: true

RSpec.shared_context 'with dependency scanning security report findings' do
  let_it_be(:yarn_lock_content) { fixture_file('security_reports/remediations/yarn.lock', dir: 'ee') }
  let_it_be(:project_files) { { 'yarn.lock' => yarn_lock_content } }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :custom_repo, namespace: group, files: project_files) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:build) { create(:ci_build, :success, name: 'dependency_scanning', pipeline: pipeline) }
  let_it_be(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning_remediation, job: build) }
  let_it_be(:report) { create(:dependency_scanning_security_report, pipeline: pipeline) }
  let_it_be(:report_finding) { report.findings.second }
end
