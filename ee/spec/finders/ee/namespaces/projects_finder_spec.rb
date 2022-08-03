# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProjectsFinder do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:namespace) { create(:group, :public) }
  let_it_be(:subgroup) { create(:group, parent: namespace) }
  let_it_be(:project_1) { create(:project, :public, group: namespace, path: 'project', name: 'Project') }
  let_it_be(:project_2) { create(:project, :public, group: namespace, path: 'test-project', name: 'Test Project') }
  let_it_be(:project_3) { create(:project, :public, group: subgroup, path: 'test-subgroup', name: 'Subgroup Project') }

  let(:params) { {} }

  let(:finder) { described_class.new(namespace: namespace, params: params, current_user: current_user) }

  subject(:projects) { finder.execute }

  describe '#execute' do
    context 'has_vulnerabilities' do
      before do
        project_1.project_setting.update!(has_vulnerabilities: true)
      end

      context 'when has_vulnerabilities is provided' do
        let(:params) { { has_vulnerabilities: true } }

        it 'returns projects with vulnerabilities' do
          expect(projects).to contain_exactly(project_1)
        end
      end

      context 'when has_vulnerabilities is not provided' do
        it 'returns all projects' do
          expect(projects).to contain_exactly(project_1, project_2)
        end
      end
    end

    context 'sorting' do
      before do
        project_1.statistics.update!(lfs_objects_size: 11, repository_size: 10)
        project_2.statistics.update!(lfs_objects_size: 10, repository_size: 12)
      end

      context 'when sort equals :storage' do
        let(:params) { { sort: :storage } }

        it 'returns projects sorted by storage' do
          expect(projects).to eq [project_2, project_1]
        end
      end

      context 'when sort does not equal :storage' do
        it 'returns all projects' do
          expect(projects).to match_array [project_1, project_2]
        end
      end
    end

    context 'has_code_coverage' do
      context 'when has_code_coverage is provided' do
        let(:params) { { has_code_coverage: true } }

        before_all do
          create(:project_ci_feature_usage, feature: :code_coverage, project: project_1, default_branch: true)
          create(:ci_daily_build_group_report_result, project: project_1, default_branch: true)
          create(:project_ci_feature_usage, feature: :code_coverage, project: project_2, default_branch: false)
          create(:ci_daily_build_group_report_result, project: project_2, default_branch: false)
        end

        it 'returns projects with code coverage on default branch based on ci feature usages' do
          record = ActiveRecord::QueryRecorder.new do
            expect(projects).to contain_exactly(project_1)
          end

          queried_ci_table = record.log.any? { |l| l.include?('ci_daily_build_group_report_results') }

          expect(queried_ci_table).to eq(false)
        end
      end

      context 'when has_code_coverage is not provided' do
        it 'returns all projects' do
          expect(projects).to contain_exactly(project_1, project_2)
        end
      end
    end
  end
end
