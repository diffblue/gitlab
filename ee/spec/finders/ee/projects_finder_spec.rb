# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsFinder do
  describe '#execute', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:ultimate_project) { create_project(:ultimate_plan) }
    let_it_be(:ultimate_project2) { create_project(:ultimate_plan) }
    let_it_be(:premium_project) { create_project(:premium_plan) }
    let_it_be(:no_plan_project) { create_project(nil) }

    let(:project_ids_relation) { nil }
    let(:finder) { described_class.new(current_user: user, params: params, project_ids_relation: project_ids_relation) }

    subject { finder.execute }

    describe 'filter by plans' do
      let(:params) { { plans: plans } }

      context 'with ultimate plan' do
        let(:plans) { ['ultimate'] }

        it { is_expected.to contain_exactly(ultimate_project, ultimate_project2) }
      end

      context 'with multiple plans' do
        let(:plans) { %w[ultimate premium] }

        it { is_expected.to contain_exactly(ultimate_project, ultimate_project2, premium_project) }
      end

      context 'with other plans' do
        let(:plans) { ['bronze'] }

        it { is_expected.to be_empty }
      end

      context 'without plans' do
        let(:plans) { nil }

        it { is_expected.to contain_exactly(ultimate_project, ultimate_project2, premium_project, no_plan_project) }
      end

      context 'with empty plans' do
        let(:plans) { [] }

        it { is_expected.to contain_exactly(ultimate_project, ultimate_project2, premium_project, no_plan_project) }
      end
    end

    context 'filter by aimed for deletion' do
      let_it_be(:params) { { aimed_for_deletion: true } }
      let_it_be(:aimed_for_deletion_project) { create(:project, :public, marked_for_deletion_at: 2.days.ago, pending_delete: false) }
      let_it_be(:pending_deletion_project) { create(:project, :public, marked_for_deletion_at: 1.month.ago, pending_delete: true) }

      it { is_expected.to contain_exactly(aimed_for_deletion_project) }
    end

    context 'filter by not aimed for deletion' do
      let_it_be(:params) { { not_aimed_for_deletion: true } }
      let_it_be(:aimed_for_deletion_project) { create(:project, :public, marked_for_deletion_at: 2.days.ago, pending_delete: false) }
      let_it_be(:pending_deletion_project) { create(:project, :public, marked_for_deletion_at: 1.month.ago, pending_delete: true) }

      it { is_expected.to contain_exactly(ultimate_project, ultimate_project2, premium_project, no_plan_project) }
    end

    context 'filter by hidden' do
      let_it_be(:hidden_project) { create(:project, :public, :hidden) }

      context 'when include hidden is true' do
        let_it_be(:params) { { include_hidden: true } }

        it { is_expected.to contain_exactly(ultimate_project, ultimate_project2, premium_project, no_plan_project, hidden_project) }
      end

      context 'when include hidden is false' do
        let_it_be(:params) { { include_hidden: false } }

        it { is_expected.to contain_exactly(ultimate_project, ultimate_project2, premium_project, no_plan_project) }
      end
    end

    private

    def create_project(plan)
      create(:project, :public, namespace: create(:namespace_with_plan, plan: plan))
    end
  end
end
