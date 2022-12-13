# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Vulnerabilities::ScannersResolver, feature_category: :vulnerability_management do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: vulnerable, args: {}, ctx: { current_user: current_user }) }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_with_no_group) { create(:project) }

    let_it_be(:user) { create(:user, security_dashboard_projects: [project_with_no_group]) }

    let_it_be(:vulnerability_scanner_1) { create(:vulnerabilities_scanner, project: project) }
    let_it_be(:finding_1) { create(:vulnerabilities_finding, project: project, scanner: vulnerability_scanner_1) }

    let_it_be(:vulnerability_scanner_2) { create(:vulnerabilities_scanner, project: project_with_no_group) }
    let_it_be(:finding_2) { create(:vulnerabilities_finding, project: project_with_no_group, scanner: vulnerability_scanner_2) }

    let(:current_user) { user }

    let(:vulnerable) { nil }

    context 'when listing scanners for group' do
      let(:vulnerable) { group }

      it { is_expected.to contain_exactly(Representation::VulnerabilityScannerEntry.new(vulnerability_scanner_1, finding_1.report_type)) }
    end

    context 'when listing scanners for project' do
      let(:vulnerable) { project_with_no_group }

      it { is_expected.to contain_exactly(Representation::VulnerabilityScannerEntry.new(vulnerability_scanner_2, finding_2.report_type)) }
    end

    context 'when listing scanners for instance dashboard' do
      let(:vulnerable) { nil }

      before do
        project_with_no_group.add_developer(current_user)
      end

      it { is_expected.to contain_exactly(Representation::VulnerabilityScannerEntry.new(vulnerability_scanner_2, finding_2.report_type)) }
    end
  end
end
