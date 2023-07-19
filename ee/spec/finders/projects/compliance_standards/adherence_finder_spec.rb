# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ComplianceStandards::AdherenceFinder, feature_category: :compliance_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:user) { create(:user) }

  let(:finder) { described_class.new(group, user, params) }
  let(:params) { {} }

  describe '#execute' do
    before_all do
      group.add_owner(user)
    end

    before do
      stub_licensed_features(group_level_compliance_dashboard: true)
    end

    subject { finder.execute }

    let_it_be(:project_1) { create(:project, namespace: group) }
    let_it_be(:project_2) { create(:project, namespace: group) }

    let_it_be(:adherence_1) do
      create(:compliance_standards_adherence, :gitlab, project: project_1,
        check_name: :prevent_approval_by_merge_request_author)
    end

    let_it_be(:adherence_2) do
      create(:compliance_standards_adherence, :gitlab, project: project_2,
        check_name: :prevent_approval_by_merge_request_author)
    end

    context 'when the user does not have permission to view the adherence report' do
      before_all do
        group.add_guest(user)
      end

      context 'when skip_authorization param is not passed' do
        it 'returns an empty array' do
          is_expected.to eq([])
        end
      end

      context 'when skip_authorization param is true' do
        let(:params) { { skip_authorization: true } }

        it 'returns the adherence records for the group' do
          is_expected.to match_array([adherence_1, adherence_2])
        end
      end
    end

    it 'returns the adherence records for the group' do
      is_expected.to match_array([adherence_1, adherence_2])
    end

    context 'for project_ids filter' do
      let(:params) { { project_ids: project_1.id } }

      it 'returns the adherence records for the specified project' do
        is_expected.to match_array([adherence_1])
      end
    end

    context 'for check_name filter' do
      let(:params) { { check_name: :prevent_approval_by_merge_request_author } }

      it 'returns the adherence records for the specified check_name' do
        is_expected.to match_array([adherence_1, adherence_2])
      end
    end

    context 'for standard filter' do
      let(:params) { { standard: :gitlab } }

      it 'returns the adherence records for the specified standard' do
        is_expected.to match_array([adherence_1, adherence_2])
      end
    end

    context 'for include_subgroups param' do
      let_it_be(:sub_group_project_1) { create(:project, namespace: sub_group) }
      let_it_be(:adherence_3) do
        create(:compliance_standards_adherence, :gitlab, project: sub_group_project_1,
          check_name: :prevent_approval_by_merge_request_author)
      end

      context 'when true' do
        let(:params) { { include_subgroups: true } }

        it 'returns the adherence records for all the projects within the group and its subgroups' do
          is_expected.to match_array([adherence_1, adherence_2, adherence_3])
        end
      end

      context 'when false' do
        let(:params) { { include_subgroups: false } }

        it 'returns the adherence records for projects within the group only' do
          is_expected.to match_array([adherence_1, adherence_2])
        end
      end

      context 'when not set' do
        it 'returns the adherence records for projects within the group only' do
          is_expected.to match_array([adherence_1, adherence_2])
        end
      end
    end
  end
end
