# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceSecurityDashboard do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:project3) { create(:project) }
  let_it_be(:pipeline1) { create(:ci_pipeline, project: project1) }
  let_it_be(:pipeline2) { create(:ci_pipeline, project: project2) }
  let_it_be(:pipeline3) { create(:ci_pipeline, project: project3) }

  let(:project_ids) { [project1.id] }
  let(:user) { create(:user) }

  before do
    project1.add_developer(user)
    project3.add_guest(user)
    user.security_dashboard_projects << [project1, project2, project3]
  end

  subject(:instance_dashboard) { described_class.new(user, project_ids: project_ids) }

  describe '#project_ids_with_security_reports' do
    context 'when given project IDs' do
      it "returns the project IDs that are also on the user's security dashboard" do
        expect(subject.project_ids_with_security_reports).to contain_exactly(project1.id)
      end
    end

    context 'when not given project IDs' do
      let(:project_ids) { [] }

      it "returns the security dashboard projects' IDs" do
        expect(subject.project_ids_with_security_reports).to contain_exactly(project1.id)
      end
    end

    context 'when the user cannot read all resources' do
      let(:project_ids) { [project1.id, project2.id] }

      it 'only includes projects they can read' do
        expect(subject.project_ids_with_security_reports).to contain_exactly(project1.id)
      end
    end

    context 'when the user can read all resources' do
      let(:project_ids) { [project1.id, project2.id] }
      let(:user) { create(:auditor) }

      it 'includes all dashboard projects' do
        expect(subject.project_ids_with_security_reports).to contain_exactly(project1.id, project2.id)
      end
    end
  end

  describe '#feature_available?' do
    subject { described_class.new(user).feature_available?(:security_dashboard) }

    context "when the feature is available for the instance's license" do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context "when the feature is not available for the instance's license" do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns false' do
        is_expected.to be_falsy
      end
    end
  end

  describe '#projects' do
    subject { instance_dashboard.projects }

    before do
      project1.team.truncate
    end

    shared_examples_for 'project permissions' do
      context 'when the `security_and_compliance` is disabled for the project' do
        before do
          ProjectFeature.update_all(security_and_compliance_access_level: Featurable::DISABLED)
        end

        it { is_expected.to be_empty }
      end

      context 'when the `security_and_compliance` is enabled for the project' do
        before do
          ProjectFeature.update_all(security_and_compliance_access_level: Featurable::ENABLED)
        end

        it { is_expected.to match_array(expected_projects) }
      end
    end

    context 'when the user is auditor' do
      let(:user) { create(:auditor) }

      it_behaves_like 'project permissions' do
        let(:expected_projects) { [project1, project2, project3] }
      end
    end

    context 'when the user is not an auditor' do
      context 'when the user is project owner' do
        let(:user) { project1.first_owner }

        it_behaves_like 'project permissions' do
          let(:expected_projects) { project1 }
        end
      end

      context 'when the user is not project owner' do
        shared_examples_for 'user with project role' do |as:, permitted:|
          let(:expected_projects) { permitted ? project1 : [] }

          before do
            project1.add_role(user, as)
          end

          it_behaves_like 'project permissions'
        end

        all_roles = Gitlab::Access.sym_options.keys
        permitted_roles = %i(developer maintainer).freeze
        unpermitted_roles = all_roles - permitted_roles

        permitted_roles.each { |role| it_behaves_like 'user with project role', as: role, permitted: true }
        unpermitted_roles.each { |role| it_behaves_like 'user with project role', as: role, permitted: false }
      end
    end
  end

  describe '#vulnerabilities' do
    let_it_be(:vulnerability1) { create(:vulnerability, project: project1) }
    let_it_be(:vulnerability2) { create(:vulnerability, project: project2) }

    context 'when the user cannot read all resources' do
      it 'returns only vulnerabilities from projects on their dashboard that they can read' do
        expect(subject.vulnerabilities).to contain_exactly(vulnerability1)
      end
    end

    context 'when the user can read all resources' do
      let(:user) { create(:auditor) }

      it "returns vulnerabilities from all projects on the user's dashboard" do
        expect(subject.vulnerabilities).to contain_exactly(vulnerability1, vulnerability2)
      end
    end
  end

  describe '#vulnerability_reads' do
    let_it_be(:vulnerability1) { create(:vulnerability, :with_findings, project: project1) }
    let_it_be(:vulnerability2) { create(:vulnerability, :with_findings, project: project2) }

    context 'when the user cannot read all resources' do
      it 'returns only vulnerability_reads from projects on their dashboard that they can read' do
        expect(subject.vulnerability_reads).to contain_exactly(vulnerability1.vulnerability_read)
      end
    end

    context 'when the user can read all resources' do
      let(:user) { create(:auditor) }

      it "returns vulnerability_reads from all projects on the user's dashboard" do
        expect(subject.vulnerability_reads).to contain_exactly(vulnerability1.vulnerability_read, vulnerability2.vulnerability_read)
      end
    end
  end

  describe '#vulnerability_scanners' do
    let_it_be(:vulnerability_scanner1) { create(:vulnerabilities_scanner, project: project1) }
    let_it_be(:vulnerability_scanner2) { create(:vulnerabilities_scanner, project: project2) }

    context 'when the user cannot read all resources' do
      it 'returns only vulnerability scanners from projects on their dashboard that they can read' do
        expect(subject.vulnerability_scanners).to contain_exactly(vulnerability_scanner1)
      end
    end

    context 'when the user can read all resources' do
      let(:user) { create(:auditor) }

      it "returns vulnerability scanners from all projects on the user's dashboard" do
        expect(subject.vulnerability_scanners).to contain_exactly(vulnerability_scanner1, vulnerability_scanner2)
      end
    end
  end

  describe '#vulnerability_historical_statistics' do
    let_it_be(:vulnerability_historical_statistic_1) { create(:vulnerability_historical_statistic, project: project1) }
    let_it_be(:vulnerability_historical_statistic_2) { create(:vulnerability_historical_statistic, project: project2) }

    context 'when the user cannot read all resources' do
      it 'returns only vulnerability scanners from projects on their dashboard that they can read' do
        expect(subject.vulnerability_historical_statistics).to contain_exactly(vulnerability_historical_statistic_1)
      end
    end

    context 'when the user can read all resources' do
      let(:user) { create(:auditor) }

      it "returns vulnerability scanners from all projects on the user's dashboard" do
        expect(subject.vulnerability_historical_statistics).to contain_exactly(vulnerability_historical_statistic_1, vulnerability_historical_statistic_2)
      end
    end
  end

  describe '#cluster_agents' do
    let_it_be(:cluster_agent_for_project_1) { create(:cluster_agent, project: project1) }
    let_it_be(:cluster_agent_for_project_3) { create(:cluster_agent, project: project3) }

    context 'when instance security dashboard has projects added' do
      it { expect(instance_dashboard.cluster_agents).to contain_exactly(cluster_agent_for_project_1) }
    end

    context 'when instance security dashboard does not have any projects added' do
      let_it_be(:other_user) { create(:user) }

      subject(:instance_dashboard) { described_class.new(other_user, project_ids: []) }

      it { expect(instance_dashboard.cluster_agents).to be_empty }
    end
  end

  describe '#full_path' do
    let(:user) { create(:user) }

    it 'returns the full_path of the user' do
      expect(subject.full_path).to eql(user.full_path)
    end
  end
end
