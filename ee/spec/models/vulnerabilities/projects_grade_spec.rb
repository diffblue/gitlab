# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ProjectsGrade, feature_category: :vulnerability_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_3) { create(:project, group: group) }
  let_it_be(:project_4) { create(:project, group: group) }
  let_it_be(:project_5) { create(:project, group: group) }
  let_it_be(:project_6) { create(:project, group: subgroup) }

  let_it_be(:vulnerability_statistic_1) { create(:vulnerability_statistic, :grade_a, project: project_1) }
  let_it_be(:vulnerability_statistic_2) { create(:vulnerability_statistic, :grade_b, project: project_2) }
  let_it_be(:vulnerability_statistic_3) { create(:vulnerability_statistic, :grade_b, project: project_3) }
  let_it_be(:vulnerability_statistic_4) { create(:vulnerability_statistic, :grade_c, project: project_4) }
  let_it_be(:vulnerability_statistic_5) { create(:vulnerability_statistic, :grade_f, project: project_5) }
  let_it_be(:vulnerability_statistic_6) { create(:vulnerability_statistic, :grade_d, project: project_6) }

  describe '.grades_for' do
    let(:compare_key) { ->(projects_grade) { [projects_grade.grade, projects_grade.project_ids.sort] } }
    let(:include_subgroups) { false }
    let(:filter) { nil }

    subject(:projects_grades) { described_class.grades_for([vulnerable], filter: filter, include_subgroups: include_subgroups) }

    context 'when the given vulnerable is a Group' do
      let(:vulnerable) { group }

      context 'when subgroups are not included' do
        context 'when the filter is not given' do
          let(:expected_projects_grades) do
            {
              vulnerable => [
                described_class.new(vulnerable, 'a', [project_1.id]),
                described_class.new(vulnerable, 'b', [project_2.id, project_3.id]),
                described_class.new(vulnerable, 'c', [project_4.id]),
                described_class.new(vulnerable, 'f', [project_5.id])
              ]
            }
          end

          it 'returns the letter grades for given vulnerable' do
            expect(projects_grades[vulnerable].map(&compare_key)).to match_array(expected_projects_grades[vulnerable].map(&compare_key))
          end
        end

        context 'when the filter is given' do
          let(:filter) { :a }
          let(:expected_projects_grades) do
            {
              vulnerable => [
                described_class.new(vulnerable, 'a', [project_1.id])
              ]
            }
          end

          it 'returns the filtered letter grade for given vulnerable' do
            expect(projects_grades[vulnerable].map(&compare_key)).to match_array(expected_projects_grades[vulnerable].map(&compare_key))
          end
        end
      end

      context 'when subgroups are included' do
        let(:include_subgroups) { true }

        context 'when the filter is not given' do
          let(:expected_projects_grades) do
            {
              vulnerable => [
                described_class.new(vulnerable, 'a', [project_1.id]),
                described_class.new(vulnerable, 'b', [project_2.id, project_3.id]),
                described_class.new(vulnerable, 'c', [project_4.id]),
                described_class.new(vulnerable, 'd', [project_6.id]),
                described_class.new(vulnerable, 'f', [project_5.id])
              ]
            }
          end

          it 'returns the letter grades for given vulnerable' do
            expect(projects_grades[vulnerable].map(&compare_key)).to match_array(expected_projects_grades[vulnerable].map(&compare_key))
          end
        end

        context 'when the filter is given' do
          let(:filter) { :d }
          let(:expected_projects_grades) do
            {
              vulnerable => [
                described_class.new(vulnerable, 'd', [project_6.id])
              ]
            }
          end

          it 'returns the filtered letter grade for given vulnerable' do
            expect(projects_grades[vulnerable].map(&compare_key)).to match_array(expected_projects_grades[vulnerable].map(&compare_key))
          end
        end
      end
    end

    context 'when the given vulnerable is an InstanceSecurityDashboard' do
      let(:user) { create(:user) }
      let(:vulnerable) { InstanceSecurityDashboard.new(user) }

      before do
        project_1.add_developer(user)
        project_2.add_developer(user)
        user.security_dashboard_projects << project_1
        user.security_dashboard_projects << project_2
      end

      context 'when the filter is not given' do
        let(:expected_projects_grades) do
          {
            vulnerable => [
              described_class.new(vulnerable, 'a', [project_1.id]),
              described_class.new(vulnerable, 'b', [project_2.id])
            ]
          }
        end

        it 'returns the letter grades for given vulnerable' do
          expect(projects_grades[vulnerable].map(&compare_key)).to match_array(expected_projects_grades[vulnerable].map(&compare_key))
        end
      end

      context 'when the filter is given' do
        let(:filter) { :b }
        let(:expected_projects_grades) { { vulnerable => [described_class.new(vulnerable, 'b', [project_2.id])] } }

        it 'returns the filtered letter grade for given vulnerable' do
          expect(projects_grades[vulnerable].map(&compare_key)).to match_array(expected_projects_grades[vulnerable].map(&compare_key))
        end
      end
    end
  end

  describe '#grade' do
    ::Vulnerabilities::Statistic.letter_grades.each do |letter|
      subject(:grade) { projects_grade.grade }

      context "when providing letter value of #{letter}" do
        let(:projects_grade) { described_class.new(nil, letter) }

        it { is_expected.to eq(letter) }
      end
    end
  end

  describe '#projects' do
    let(:projects_grade) { described_class.new(group, 1, [project_3.id, project_4.id, project_6.id], include_subgroups: include_subgroups) }

    subject(:projects) { projects_grade.projects }

    context 'when include_subgroups is set to false' do
      let(:include_subgroups) { false }
      let(:expected_projects) { [project_3, project_4] }

      it { is_expected.to match_array(expected_projects) }

      it 'preloads vulnerability statistic once for whole collection' do
        control_count = ActiveRecord::QueryRecorder.new { described_class.new(group, 1, [project_3.id]).projects.map(&:vulnerability_statistic) }.count

        expect { described_class.new(group, 1, [project_3.id, project_4.id]).projects.map(&:vulnerability_statistic) }.not_to exceed_query_limit(control_count)
      end
    end

    context 'when include_subgroups is set to true' do
      let(:include_subgroups) { true }
      let(:expected_projects) { [project_3, project_4, project_6] }

      it { is_expected.to match_array(expected_projects) }

      it 'preloads vulnerability statistic once for whole collection' do
        control_count = ActiveRecord::QueryRecorder.new { described_class.new(group, 1, [project_3.id]).projects.map(&:vulnerability_statistic) }.count

        expect { described_class.new(group, 1, [project_3.id, project_4.id]).projects.map(&:vulnerability_statistic) }.not_to exceed_query_limit(control_count)
      end
    end
  end

  describe '#count' do
    let(:projects_grade) { described_class.new(group, 1, [project_3.id, project_4.id]) }

    subject(:projects) { projects_grade.count }

    it { is_expected.to eq 2 }
  end
end
