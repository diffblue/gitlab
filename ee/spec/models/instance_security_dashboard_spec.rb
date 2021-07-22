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

  subject { described_class.new(user, project_ids: project_ids) }

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
    context 'when the user cannot read all resources' do
      context 'when the `security_and_compliance` is enabled for the project' do
        before do
          ProjectFeature.update_all(security_and_compliance_access_level: Featurable::ENABLED)
        end

        it 'returns only projects on their dashboard that they can read' do
          expect(subject.projects).to contain_exactly(project1)
        end
      end

      context 'when the `security_and_compliance` is disabled for the project' do
        before do
          project1.project_feature.update_column(:security_and_compliance_access_level, Featurable::DISABLED)
        end

        it 'returns only projects on their dashboard that they can read' do
          expect(subject.projects).to be_empty
        end
      end
    end

    context 'when the user can read all resources' do
      let(:project_ids) { [project1.id, project2.id] }
      let(:user) { create(:auditor) }

      context 'when the `security_and_compliance` is enabled for the project' do
        before do
          ProjectFeature.update_all(security_and_compliance_access_level: Featurable::ENABLED)
        end

        it "returns all projects on the user's dashboard" do
          expect(subject.projects).to contain_exactly(project1, project2, project3)
        end
      end

      context 'when the `security_and_compliance` is disabled for the project' do
        before do
          project1.project_feature.update_column(:security_and_compliance_access_level, Featurable::DISABLED)
        end

        it "returns only the feature enabled projects on the user's dashboard" do
          expect(subject.projects).to contain_exactly(project2, project3)
        end
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

  describe '#full_path' do
    let(:user) { create(:user) }

    it 'returns the full_path of the user' do
      expect(subject.full_path).to eql(user.full_path)
    end
  end
end
