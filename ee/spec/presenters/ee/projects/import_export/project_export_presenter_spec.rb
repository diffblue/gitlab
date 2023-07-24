# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::ProjectExportPresenter, feature_category: :importers do
  let_it_be(:project) { create(:project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:current_user) { build_stubbed(:user) }

  describe '#approval_rules' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate
    let_it_be(:any_approver_rule) { create(:approval_project_rule, :any_approver_rule, project: project) }
    let_it_be(:license_scanning_rule) { create(:approval_project_rule, :license_scanning, project: project) }
    let_it_be(:code_coverage) { create(:approval_project_rule, :code_coverage, project: project) }
    let_it_be(:scan_finding) { create(:approval_project_rule, :scan_finding, project: project) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    subject(:result) { described_class.new(project, current_user: current_user).approval_rules }

    it 'does not include rules created from scan result policies' do
      is_expected.to match_array([any_approver_rule, code_coverage])
    end
  end
end
