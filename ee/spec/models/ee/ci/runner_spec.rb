# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Ci::Runner do
  let(:shared_runners_minutes) { 400 }

  before do
    allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { shared_runners_minutes }
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
               public_projects_minutes_cost_factor: 0)
      end

      context 'with private visibility level' do
        let(:project) { create(:project, visibility_level: ::Gitlab::VisibilityLevel::PRIVATE) }

        it { is_expected.to eq(1.1) }

        context 'with unlimited minutes' do
          let(:shared_runners_minutes) { 0 }

          it { is_expected.to eq(0) }
        end
      end

      context 'with public visibility level' do
        let(:project) { create(:project, namespace: namespace, visibility_level: ::Gitlab::VisibilityLevel::PUBLIC) }

        context 'after the release date for public project cost factors' do
          let(:namespace) do
            create(:group, created_at: Date.new(2021, 7, 17))
          end

          before do
            allow(Gitlab).to receive(:com?).and_return(true)
          end

          it { is_expected.to eq(0.008) }
        end

        context 'before the release date for public project cost factors' do
          let(:namespace) do
            create(:group, created_at: Date.new(2021, 7, 16))
          end

          it { is_expected.to eq(0.0) }
        end
      end

      context 'with internal visibility level' do
        let(:project) { create(:project, visibility_level: ::Gitlab::VisibilityLevel::INTERNAL) }

        it { is_expected.to eq(1.1) }
      end

      context 'with invalid visibility level' do
        let(:project) { create(:project, visibility_level: 123) }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
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

  describe '#visibility_levels_without_minutes_quota' do
    subject { runner.visibility_levels_without_minutes_quota }

    context 'with group type runner' do
      let(:runner) { create(:ci_runner, :group) }

      it { is_expected.to match(::Gitlab::VisibilityLevel.options.values) }
    end

    context 'with project type runner' do
      let(:runner) { create(:ci_runner, :project) }

      it { is_expected.to match(::Gitlab::VisibilityLevel.options.values) }
    end

    context 'with instance type runner' do
      context 'with both public and private cost factor being positive' do
        let(:runner) do
          create(:ci_runner,
                :instance,
                private_projects_minutes_cost_factor: 1.1,
                public_projects_minutes_cost_factor: 2.2)
        end

        it { is_expected.to eq([]) }
      end

      context 'with both public and private cost factor being zero' do
        let(:runner) do
          create(:ci_runner,
                :instance,
                private_projects_minutes_cost_factor: 0.0,
                public_projects_minutes_cost_factor: 0.0)
        end

        it { is_expected.to match(::Gitlab::VisibilityLevel.options.values) }
      end

      context 'with only private cost factor being positive' do
        let(:runner) do
          create(:ci_runner,
                :instance,
                private_projects_minutes_cost_factor: 1.0,
                public_projects_minutes_cost_factor: 0.0)
        end

        it { is_expected.to match([::Gitlab::VisibilityLevel::PUBLIC]) }
      end
    end
  end

  describe '.any_shared_runners_with_enabled_cost_factor' do
    subject(:runners) { Ci::Runner.any_shared_runners_with_enabled_cost_factor?(project) }

    let_it_be(:namespace) { create(:group) }

    context 'when project is public' do
      let_it_be(:project) { create(:project, namespace: namespace, visibility_level: ::Gitlab::VisibilityLevel::PUBLIC) }
      let_it_be(:runner) { create(:ci_runner, :instance, public_projects_minutes_cost_factor: 0.0) }

      context 'when cost factor is forced' do
        before do
          allow(project).to receive(:force_cost_factor?).and_return(true)
        end

        it 'returns true' do
          expect(runners).to be_truthy
        end
      end

      context 'when cost factor is not forced' do
        context 'when public cost factor is greater than zero' do
          before do
            runner.update!(public_projects_minutes_cost_factor: 1.0)
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
    end

    context 'when project is private' do
      let_it_be(:project) { create(:project, namespace: namespace, visibility_level: ::Gitlab::VisibilityLevel::PRIVATE) }
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
end
