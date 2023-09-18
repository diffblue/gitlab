# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::VulnerabilitiesFinder, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let_it_be(:archived_project) do
    create(:project, :archived, namespace: group).tap do |p|
      create(:vulnerability, :with_finding, project: p)
    end
  end

  let_it_be(:vulnerability1) do
    create(:vulnerability, :with_findings, :with_issue_links, severity: :low, report_type: :sast, state: :detected, project: project)
  end

  let_it_be(:vulnerability2) do
    create(:vulnerability, :with_findings, resolved_on_default_branch: true, severity: :high, report_type: :dependency_scanning, state: :confirmed, project: project)
  end

  let_it_be(:vulnerability3) do
    create(:vulnerability, :with_findings, severity: :medium, report_type: :dast, state: :dismissed, project: project)
  end

  let(:archive_associated_vulnerabilities) { archived_project.vulnerabilities }
  let(:filters) { {} }
  let(:vulnerable) { project }

  shared_context 'with vulnerability dismissed with a reason' do
    let_it_be(:dismissed_vulnerability) { create(:vulnerability, :dismissed, report_type: :dependency_scanning, severity: :low, project: project) }
    let_it_be(:dismissed_vulnerability_read) do
      create(
        :vulnerability_read,
        :used_in_tests,
        report_type: dismissed_vulnerability.report_type,
        state: dismissed_vulnerability.state,
        severity: dismissed_vulnerability.severity,
        vulnerability: dismissed_vulnerability,
        project: project
      )
    end
  end

  subject { described_class.new(vulnerable, filters).execute }

  it 'returns vulnerabilities of a project' do
    expect(subject).to match_array(project.vulnerabilities)
  end

  context 'when not given a second argument' do
    subject { described_class.new(project).execute }

    it 'does not filter the vulnerability list' do
      expect(subject).to match_array(project.vulnerabilities)
    end
  end

  context 'when using the include_archived_projects param' do
    using RSpec::Parameterized::TableSyntax

    let(:result_including_archived) { result_excluding_archived + archive_associated_vulnerabilities }
    let(:result_excluding_archived) { group.vulnerabilities.without_archived_projects }

    before do
      project.update!(namespace: group)
    end

    where(:vulnerable_object, :include_archived_projects, :result) do
      ref(:archived_project) | true   | ref(:archive_associated_vulnerabilities)
      ref(:archived_project) | false  | ref(:archive_associated_vulnerabilities)
      ref(:group)            | true   | ref(:result_including_archived)
      ref(:group)            | false  | ref(:result_excluding_archived)
    end

    with_them do
      let(:vulnerable) { vulnerable_object }
      let(:filters) { super().merge(include_archived_projects: include_archived_projects) }

      it 'filters out vulnerabilities associated with archived projects as defined' do
        expect(subject).to match_array(result)
      end
    end
  end

  context 'when filtered by report type' do
    let(:filters) { { report_type: %w[sast dast] } }

    it 'only returns vulnerabilities matching the given report types' do
      is_expected.to contain_exactly(vulnerability1, vulnerability3)
    end
  end

  context 'when filtered by severity' do
    let(:filters) { { severity: %w[medium high] } }

    it 'only returns vulnerabilities matching the given severities' do
      is_expected.to contain_exactly(vulnerability3, vulnerability2)
    end
  end

  context 'when filtered by state' do
    let(:filters) { { state: %w[detected confirmed] } }

    it 'only returns vulnerabilities matching the given states' do
      is_expected.to contain_exactly(vulnerability1, vulnerability2)
    end

    context 'when given multiple states and a dismissal reason' do
      include_context 'with vulnerability dismissed with a reason'

      let(:filters) { { state: %w[confirmed], dismissal_reason: %w[used_in_tests] } }

      it 'returns vulnerabilites matching the state OR dismissal_reason' do
        is_expected.to contain_exactly(vulnerability2, dismissed_vulnerability)
      end
    end

    context 'when given a dismissal reason only' do
      include_context 'with vulnerability dismissed with a reason'

      let(:filters) { { dismissal_reason: %w[used_in_tests] } }

      it 'only returns dismissed vulnerabilities with the given dismissal reason' do
        is_expected.to contain_exactly(dismissed_vulnerability)
      end
    end
  end

  context 'when filtered by scanner external ID' do
    let(:filters) { { scanner: [vulnerability1.finding_scanner_external_id, vulnerability2.finding_scanner_external_id] } }

    it 'only returns vulnerabilities matching the given scanner IDs' do
      is_expected.to contain_exactly(vulnerability1, vulnerability2)
    end
  end

  context 'when filtered by scanner_id' do
    let(:filters) { { scanner_id: [vulnerability1.finding_scanner_id, vulnerability3.finding_scanner_id] } }

    it 'only returns vulnerabilities matching the given scanner IDs' do
      is_expected.to contain_exactly(vulnerability1, vulnerability3)
    end
  end

  context 'when the vulnerable object is a Group' do
    let(:vulnerable) { group }
    let(:another_project) { create(:project, namespace: group) }

    let!(:another_vulnerability) { create(:vulnerability, :with_findings, project: another_project) }

    let_it_be(:group) { create(:group) }
    let_it_be(:archived_project) { create(:project, :archived, namespace: group) }

    before do
      project.update!(namespace: group)
    end

    context 'when filtered by project' do
      let!(:archived_vulnerability) { create(:vulnerability, :with_findings, project: archived_project) }
      let(:filters) { { project_id: [another_project.id, archived_project.id] } }

      it 'only returns vulnerabilities matching the given projects' do
        is_expected.to contain_exactly(another_vulnerability)
      end

      context 'when including archived projects' do
        let(:filters) { super().merge(include_archived_projects: true) }

        it 'returns vulnerabilities matching the given projects' do
          is_expected.to contain_exactly(another_vulnerability, archived_vulnerability)
        end
      end
    end
  end

  context 'when sorted' do
    let(:filters) { { sort: method } }

    context 'ascending by severity' do
      let(:method) { :severity_asc }

      it { is_expected.to eq([vulnerability1, vulnerability3, vulnerability2]) }
    end

    context 'descending by severity' do
      let(:method) { :severity_desc }

      it { is_expected.to eq([vulnerability2, vulnerability3, vulnerability1]) }
    end
  end

  context 'when filtered by has_issues argument' do
    let(:filters) { { has_issues: has_issues } }

    context 'when has_issues is set to true' do
      let(:has_issues) { true }

      it 'only returns vulnerabilities that have issues' do
        is_expected.to contain_exactly(vulnerability1)
      end
    end

    context 'when has_issues is set to false' do
      let(:has_issues) { false }

      it 'only returns vulnerabilities that does not have issues' do
        is_expected.to contain_exactly(vulnerability2, vulnerability3)
      end
    end
  end

  context 'when filtered by has_resolution argument' do
    let(:filters) { { has_resolution: has_resolution } }

    context 'when has_resolution is set to true' do
      let(:has_resolution) { true }

      it 'only returns vulnerabilities that have resolution' do
        is_expected.to contain_exactly(vulnerability2)
      end
    end

    context 'when has_resolution is set to false' do
      let(:has_resolution) { false }

      it 'only returns vulnerabilities that do not have resolution' do
        is_expected.to contain_exactly(vulnerability1, vulnerability3)
      end
    end
  end

  context 'when filtered by more than one property' do
    let_it_be(:vulnerability4) do
      create(:vulnerability, :with_findings, severity: :medium, report_type: :sast, state: :detected, project: project)
    end

    let(:filters) { { report_type: %w[sast], severity: %w[medium] } }

    it 'only returns vulnerabilities matching all of the given filters' do
      is_expected.to contain_exactly(vulnerability4)
    end
  end

  context 'when filtered by image' do
    let_it_be(:cluster_vulnerability) { create(:vulnerability, :cluster_image_scanning, project: project) }
    let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, project: project, vulnerability: cluster_vulnerability) }

    let(:filters) { { image: [finding.location['image']] } }
    let(:feature_enabled) { true }

    it 'only returns vulnerabilities matching the given image' do
      is_expected.to contain_exactly(cluster_vulnerability)
    end

    context 'when different report_type is passed' do
      let(:filters) { { report_type: %w[dast], image: [finding.location['image']] } }

      it 'returns empty list' do
        is_expected.to be_empty
      end
    end

    context 'when vulnerable is InstanceSecurityDashboard' do
      let(:vulnerable) { InstanceSecurityDashboard.new(project.users.first) }

      it 'does not include cluster vulnerability' do
        is_expected.not_to contain_exactly(cluster_vulnerability)
      end
    end
  end

  context 'when filtered by cluster_id' do
    let_it_be(:cluster_vulnerability) { create(:vulnerability, :cluster_image_scanning, project: project) }
    let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, project: project, vulnerability: cluster_vulnerability) }

    let(:filters) { { cluster_id: [finding.location['kubernetes_resource']['cluster_id']] } }

    it 'only returns vulnerabilities matching the given cluster_id' do
      is_expected.to contain_exactly(cluster_vulnerability)
    end

    context 'when different report_type is passed' do
      let(:filters) { { report_type: %w[dast], cluster_id: [finding.location['kubernetes_resource']['cluster_id']] } }

      it 'returns empty list' do
        is_expected.to be_empty
      end
    end
  end

  context 'when filtered by cluster_agent_id' do
    let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }
    let_it_be(:cluster_vulnerability) { create(:vulnerability, :cluster_image_scanning, project: project) }
    let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, agent_id: cluster_agent.id.to_s, project: project, vulnerability: cluster_vulnerability) }

    let(:filters) { { cluster_agent_id: [finding.location['kubernetes_resource']['agent_id']] } }

    it 'only returns vulnerabilities matching the given agent_id' do
      is_expected.to contain_exactly(cluster_vulnerability)
    end

    context 'when different report_type is passed' do
      let(:filters) { { report_type: %w[dast], cluster_agent_id: [finding.location['kubernetes_resource']['agent_id']] } }

      it 'returns empty list' do
        is_expected.to be_empty
      end
    end
  end

  context 'when there are vulnerabilities on non default branches' do
    let_it_be(:vulnerability4) do
      create(:vulnerability, report_type: :dast, project: project, present_on_default_branch: false)
    end

    let(:filters) { { report_type: %w[dast] } }

    it 'only returns vulnerabilities on the default branch by default' do
      is_expected.to contain_exactly(vulnerability3)
    end

    context 'when present_on_default_branch is passed' do
      let(:filters) { { report_type: %w[dast], present_on_default_branch: false } }

      it 'returns vulnerabilities on all branches' do
        is_expected.to contain_exactly(vulnerability3, vulnerability4)
      end
    end
  end
end
