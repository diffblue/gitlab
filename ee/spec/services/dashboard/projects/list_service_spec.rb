# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::Projects::ListService, feature_category: :projects do
  let!(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
  let(:namespace) { create(:namespace, :with_namespace_settings, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:service) { described_class.new(user, feature: :operations_dashboard) }

  describe '#execute' do
    let(:result) { service.execute(projects) }

    shared_examples 'project not found' do
      it 'returns an empty list' do
        expect(result).to be_empty
      end
    end

    shared_examples 'project found' do
      it 'returns the project' do
        expect(result).to contain_exactly(project)
      end
    end

    before do
      project.add_developer(user)
    end

    context 'when passing a project id' do
      let(:projects) { [project.id] }

      it_behaves_like 'project found'
    end

    context 'when passing a project record' do
      let(:projects) { [project] }

      it_behaves_like 'project found'
    end

    context 'when passing invalid project id' do
      let(:projects) { [-1] }

      it_behaves_like 'project not found'
    end

    context 'with insufficient access' do
      let(:projects) { [project] }

      before do
        project.add_reporter(user)
      end

      it_behaves_like 'project not found'
    end

    describe 'checking license', :saas, :without_license do
      let(:projects) { [project] }

      using RSpec::Parameterized::TableSyntax

      before do
        stub_application_setting(check_namespace_plan: true)
        create(:gitlab_subscription, :ultimate, namespace: namespace)
      end

      where(:plan, :trial, :expired, :available) do
        License::ULTIMATE_PLAN  | false | false | true
        License::ULTIMATE_PLAN  | false | true  | true
        License::ULTIMATE_PLAN  | true  | false | false
        License::ULTIMATE_PLAN  | true  | true  | false
        License::PREMIUM_PLAN   | false | false | true
        nil                     | false | false | false
      end

      with_them do
        let!(:license) { create(:license, plan: plan, trial: trial, expired: expired) }

        if params[:available]
          it_behaves_like 'project found'
        else
          it_behaves_like 'project not found'
        end
      end
    end

    describe 'checking plans', :saas do
      let(:projects) { [project] }

      using RSpec::Parameterized::TableSyntax

      where(:check_namespace_plan, :plan, :available) do
        true  | :gold     | true
        true  | :premium  | true
        true  | :ultimate | true
        true  | nil       | false
        false | :gold     | true
        false | :premium  | true
        false | :ultimate | true
        false | nil       | true
      end

      with_them do
        before do
          stub_application_setting(check_namespace_plan: check_namespace_plan)

          create(:gitlab_subscription, plan, namespace: namespace) if plan
        end

        if params[:available]
          it_behaves_like 'project found'
        else
          it_behaves_like 'project not found'
        end

        context 'if :include_unavailable option is provided' do
          let(:result) { service.execute(projects, include_unavailable: true) }

          it_behaves_like 'project found'
        end
      end
    end

    describe 'checking availability of public projects on GitLab.com', :saas do
      let(:projects) { [project] }

      using RSpec::Parameterized::TableSyntax

      where(:check_namespace_plan, :project_visibility, :namespace_visibility, :available) do
        public_visibility = Gitlab::VisibilityLevel::PUBLIC
        private_visibility = Gitlab::VisibilityLevel::PRIVATE

        true  | public_visibility  | public_visibility  | true
        true  | private_visibility | public_visibility  | false
        true  | public_visibility  | private_visibility | false
        true  | private_visibility | private_visibility | false
        false | public_visibility  | public_visibility  | true
        false | private_visibility | public_visibility  | true
        false | public_visibility  | private_visibility | true
        false | private_visibility | private_visibility | true
      end

      with_them do
        before do
          stub_application_setting(check_namespace_plan: check_namespace_plan)
          project.update_column(:visibility_level, project_visibility)
          namespace.update!(visibility_level: namespace_visibility)
        end

        if params[:available]
          it_behaves_like 'project found'
        else
          it_behaves_like 'project not found'
        end
      end
    end

    context 'when the user is an auditor' do
      let(:projects) { [project] }
      let(:user) { create(:auditor) }

      it_behaves_like 'project found'
    end
  end
end
