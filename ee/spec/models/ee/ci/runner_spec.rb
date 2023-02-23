# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runner, feature_category: :continuous_integration do
  let(:shared_runners_minutes) { 400 }

  before do
    allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { shared_runners_minutes }
  end

  describe 'ci associations' do
    it 'has one cost setting' do
      is_expected.to have_one(:cost_settings)
      .inverse_of(:runner)
      .class_name('Ci::Minutes::CostSetting')
      .with_foreign_key(:runner_id)
    end
  end

  describe '#cost_factor_for_project' do
    subject { runner.cost_factor_for_project(project) }

    context 'with group type runner' do
      let(:runner) { create(:ci_runner, :group) }

      ::Gitlab::VisibilityLevel.options.each do |level_name, level_value|
        context "with #{level_name}" do
          let(:project) { create(:project, visibility_level: level_value) }

          it { is_expected.to eq(0.0) }
        end
      end
    end

    context 'with project type runner' do
      let(:runner) { create(:ci_runner, :project) }

      ::Gitlab::VisibilityLevel.options.each do |level_name, level_value|
        context "with #{level_name}" do
          let(:project) { create(:project, visibility_level: level_value) }

          it { is_expected.to eq(0.0) }
        end
      end
    end

    context 'with instance type runner' do
      let(:runner) do
        create(:ci_runner,
               :instance,
               private_projects_minutes_cost_factor: 1.1,
               public_projects_minutes_cost_factor: 0.008)
      end

      context 'with private visibility level' do
        let(:project) { create(:project, :private) }

        it { is_expected.to eq(1.1) }

        context 'with unlimited minutes' do
          let(:shared_runners_minutes) { 0 }

          it { is_expected.to eq(0) }
        end
      end

      context 'with public visibility level' do
        let(:project) { create(:project, :public) }

        it { is_expected.to eq(0.008) }
      end

      context 'with internal visibility level' do
        let(:project) { create(:project, :internal) }

        it { is_expected.to eq(1.1) }
      end
    end
  end

  describe '#cost_factor_enabled?' do
    let_it_be_with_reload(:project) do
      namespace = create(:group, created_at: Date.new(2021, 7, 16))
      create(:project, namespace: namespace)
    end

    context 'when the project has any cost factor' do
      let(:runner) do
        create(:ci_runner, :instance,
          private_projects_minutes_cost_factor: 1,
          public_projects_minutes_cost_factor: 0)
      end

      subject { runner.cost_factor_enabled?(project) }

      it { is_expected.to be_truthy }

      context 'with unlimited minutes' do
        let(:shared_runners_minutes) { 0 }

        it { is_expected.to be_falsy }
      end
    end

    context 'when the project has no cost factor' do
      it 'returns false' do
        runner = create(:ci_runner, :instance,
                        private_projects_minutes_cost_factor: 0,
                        public_projects_minutes_cost_factor: 0)

        expect(runner.cost_factor_enabled?(project)).to be_falsy
      end
    end
  end

  describe '.any_shared_runners_with_enabled_cost_factor' do
    subject(:runners) { Ci::Runner.any_shared_runners_with_enabled_cost_factor?(project) }

    let_it_be(:namespace) { create(:group) }

    context 'when project is public' do
      let_it_be(:project) { create(:project, :public, namespace: namespace) }
      let_it_be(:runner) { create(:ci_runner, :instance, public_projects_minutes_cost_factor: 0.0) }

      context 'when public cost factor is greater than zero' do
        before do
          runner.update!(public_projects_minutes_cost_factor: 0.008)
        end

        it 'returns true' do
          expect(runners).to be_truthy
        end
      end

      context 'when public cost factor is zero' do
        it 'returns false' do
          expect(runners).to be_falsey
        end
      end
    end

    context 'when project is private' do
      let_it_be(:project) { create(:project, :private, namespace: namespace) }
      let_it_be(:runner) { create(:ci_runner, :instance, private_projects_minutes_cost_factor: 1.0) }

      context 'when private cost factor is greater than zero' do
        it 'returns true' do
          expect(runners).to be_truthy
        end
      end

      context 'when private cost factor is zero' do
        before do
          runner.update!(private_projects_minutes_cost_factor: 0.0)
        end

        it 'returns false' do
          expect(runners).to be_falsey
        end
      end
    end
  end

  describe '#allowed_for_plans?', :saas do
    let(:namespace) { create(:namespace_with_plan, plan: plan) }
    let(:project) { create(:project, namespace: namespace) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, pipeline: pipeline) }

    subject { create(:ci_runner, :instance, allowed_plans: allowed_plans).allowed_for_plans?(build) }

    context 'when allowed plans are not defined' do
      let(:allowed_plans) { [] }
      let(:plan) { :premium_plan }

      it { is_expected.to be_truthy }
    end

    context 'when allowed_plans are defined' do
      let(:allowed_plans) { %w(silver premium) }

      context 'when plans match allowed plans' do
        let(:plan) { :premium_plan }

        it { is_expected.to be_truthy }
      end

      context 'when plans do not match allowed plans' do
        let(:plan) { :ultimate_plan }

        it { is_expected.to be_falsey }
      end
    end

    context 'when ci_runner_separation_by_plan feature flag is disabled' do
      let(:allowed_plans) { %w(silver premium) }
      let(:plan) { :ultimate_plan }

      before do
        stub_feature_flags(ci_runner_separation_by_plan: false)
      end

      it { is_expected.to be_truthy }
    end
  end
end
