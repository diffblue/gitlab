# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::RequirementsFinder do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_user) { create(:user, username: 'projectusername').tap { |u| project.add_developer(u) } }
  let_it_be(:other_user) { create(:user, username: 'otheruser123') }
  let_it_be(:requirement1) { create(:requirement, project: project, state: 'opened', author: project_user, updated_at: 3.days.ago, title: 'make it better with serverless') }
  let_it_be(:requirement2) { create(:requirement, project: project, state: 'opened', author: project_user, updated_at: 1.day.ago, title: 'make it not crash') }
  let_it_be(:requirement3) { create(:requirement, project: project, state: 'archived', author: other_user, updated_at: 2.days.ago, title: 'good with memory') }
  let_it_be(:requirement4) { create(:requirement, state: 'opened', title: 'mystery requirement') }

  subject { described_class.new(project_user, params).execute }

  describe '#execute' do
    context 'when requirements are enabled' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when project is not set' do
        let(:params) { {} }

        it 'does not return any requirements' do
          is_expected.to be_empty
        end
      end

      context 'when project is set' do
        let(:params) { { project_id: project.id } }

        it 'returns all requirements in the project' do
          is_expected.to match_array([requirement1, requirement2, requirement3])
        end
      end

      context 'when state is set' do
        let(:params) { { project_id: project.id, state: 'opened' } }

        it 'returns matched requirements' do
          is_expected.to match_array([requirement1, requirement2])
        end
      end

      context 'when iid is set' do
        let(:params) { { project_id: project.id, iids: [requirement2.iid, requirement3.iid] } }

        it 'returns matched requirements' do
          is_expected.to match_array([requirement2, requirement3])
        end
      end

      context 'when last_test_report_state is set' do
        let(:params) { { project_id: project.id, last_test_report_state: 'passed' } }

        it 'returns matched requirements' do
          create(:test_report, state: :passed)
          create(:test_report, requirement_issue: requirement1.requirement_issue, state: :failed)
          create(:test_report, requirement_issue: requirement1.requirement_issue, state: :passed)
          create(:test_report, requirement_issue: requirement3.requirement_issue, state: :passed)

          is_expected.to match_array([requirement1, requirement3])
        end

        context 'when last_test_report_state is not valid' do
          let(:params) { { project_id: project.id, last_test_report_state: 'not_valid' } }

          it 'does not filter requirements' do
            is_expected.to match_array([requirement1, requirement2, requirement3])
          end

          it 'does not raise error' do
            expect { subject }.not_to raise_error
          end
        end
      end

      context 'when user can not read requirements in the project' do
        let(:user) { create(:user) }
        let(:params) { { project_id: project.id } }

        it 'does not return any requirements' do
          expect(described_class.new(user, params).execute).to be_empty
        end
      end

      describe 'filter by author' do
        using RSpec::Parameterized::TableSyntax

        let(:params) { { project_id: project.id, author_username: author_username } }

        where(:author_username, :filtered_requirements) do
          'projectusername'                | [:requirement1, :requirement2]
          'nonexistent_user'               | []
          nil                              | [:requirement3, :requirement2, :requirement1]
          %w[projectusername otheruser123] | [:requirement3, :requirement2, :requirement1]
          %w[nonexistentuser nonsense]     | []
        end

        with_them do
          it 'returns the requirements filtered' do
            expect(subject).to match_array(filtered_requirements.map { |name| public_send(name) })
          end
        end
      end

      describe 'filter by search' do
        using RSpec::Parameterized::TableSyntax

        let(:params) { { project_id: project.id, search: query } }

        where(:query, :filtered_requirements) do
          'nonsense'    | []
          'serverless'  | [:requirement1]
          'with'        | [:requirement1, :requirement3]
          nil           | [:requirement3, :requirement2, :requirement1]
          ""            | [:requirement3, :requirement2, :requirement1]
        end

        with_them do
          it 'returns the requirements filtered' do
            expect(subject).to match_array(filtered_requirements.map { |name| public_send(name) })
          end
        end
      end

      describe 'ordering' do
        using RSpec::Parameterized::TableSyntax

        let(:params) { { project_id: project.id, sort: sort } }

        where(:sort, :ordered_requirements) do
          'id_asc'          | [:requirement1, :requirement2, :requirement3]
          'id_desc'         | [:requirement3, :requirement2, :requirement1]
          'updated_at_asc'  | [:requirement1, :requirement3, :requirement2]
          'updated_at_desc' | [:requirement2, :requirement3, :requirement1]
          'err'             | [:requirement3, :requirement2, :requirement1]
        end

        with_them do
          it 'returns the requirements ordered' do
            expect(subject).to eq(ordered_requirements.map { |name| public_send(name) })
          end
        end
      end
    end

    context 'when requirements are disabled' do
      before do
        stub_licensed_features(requirements: false)
      end

      context 'when project is set' do
        let(:params) { { project_id: project.id } }

        it 'does not return any requirements' do
          is_expected.to be_empty
        end
      end
    end
  end
end
