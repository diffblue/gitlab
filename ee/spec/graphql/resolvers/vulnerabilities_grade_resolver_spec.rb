# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::VulnerabilitiesGradeResolver do
  include GraphqlHelpers

  subject do
    force(resolve(described_class, obj: group, args: args, ctx: { current_user: user }))
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:project_in_subgroup) { create(:project, namespace: subgroup) }
  let_it_be(:user) { create(:user) }
  let_it_be(:include_subgroups) { nil }

  let_it_be(:vulnerability_statistic_1) { create(:vulnerability_statistic, :grade_f, project: project) }
  let_it_be(:vulnerability_statistic_2) { create(:vulnerability_statistic, :grade_d, project: project_in_subgroup) }

  describe '#resolve' do
    let(:letter_grade) { nil }
    let(:args) { { include_subgroups: include_subgroups, letter_grade: letter_grade } }

    context 'when security_dashboards are disabled' do
      context 'when user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.to be_blank }
      end

      context 'when user is logged in' do
        let(:current_user) { user }

        context 'when user does not have permissions' do
          it { is_expected.to be_blank }
        end

        context 'when user has permission to access vulnerabilities' do
          before do
            project.add_developer(current_user)
            group.add_developer(current_user)
          end

          context 'when include_subgroups is set to true' do
            let(:include_subgroups) { true }

            it { is_expected.to be_blank }

            context 'when the letter grade is given' do
              let(:letter_grade) { :d }

              it { is_expected.to be_blank }
            end
          end

          context 'when include_subgroups is set to true' do
            let(:include_subgroups) { false }

            it { is_expected.to be_blank }

            context 'when the letter grade is given' do
              let(:letter_grade) { :d }

              it { is_expected.to be_blank }
            end
          end
        end
      end
    end

    context 'when security_dashboards are enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.to be_blank }
      end

      context 'when user is logged in' do
        let(:current_user) { user }

        context 'when user does not have permissions' do
          it { is_expected.to be_blank }
        end

        context 'when user has permission to access vulnerabilities' do
          before do
            project.add_developer(current_user)
            group.add_developer(current_user)
          end

          context 'when include_subgroups is set to true' do
            let(:include_subgroups) { true }

            it 'returns project grades for projects in group and its subgroups' do
              expect(subject.map(&:grade)).to match_array(%w[d f])
            end

            context 'when the letter grade is given' do
              let(:letter_grade) { :d }

              it 'returns only the requested grade' do
                expect(subject.map(&:grade)).to match_array(%w[d])
              end
            end
          end

          context 'when include_subgroups is set to true' do
            let(:include_subgroups) { false }

            it 'returns project grades for projects in group only' do
              expect(subject.map(&:grade)).to match_array(%w[f])
            end

            context 'when the letter grade is given' do
              let(:letter_grade) { :d }

              it 'returns only the requested grade' do
                expect(subject.map(&:grade)).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
