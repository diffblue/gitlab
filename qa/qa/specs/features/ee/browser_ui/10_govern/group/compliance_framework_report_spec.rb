# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :skip_live_env, product_group: :compliance do
    describe 'Compliance Framework Report' do
      let!(:subgroup) do
        Resource::Group.fabricate_via_api! do |group|
          group.path = "compliance-#{Faker::Alphanumeric.alphanumeric(number: 8)}"
        end
      end

      let!(:top_level_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-compliance-framework-report'
          project.group = subgroup.sandbox
        end
      end

      let!(:project_without_framework) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-without-compliance-framework'
          project.group = subgroup.sandbox
        end
      end

      let!(:subgroup_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'subgroup-project-compliance-framework-report'
          project.group = subgroup
        end
      end

      let!(:default_compliance_framework) do
        QA::EE::Resource::ComplianceFramework.fabricate_via_api! do |framework|
          framework.group = subgroup.sandbox
          framework.default = true
        end
      end

      let!(:another_framework) do
        QA::EE::Resource::ComplianceFramework.fabricate_via_api! do |framework|
          framework.group = subgroup
        end
      end

      before do
        Flow::Login.sign_in

        # Apply different compliance frameworks to two projects so that we can confirm their correct assignment
        top_level_project.compliance_framework = default_compliance_framework
        subgroup_project.compliance_framework = another_framework
      end

      after do
        default_compliance_framework.remove_via_api!(delete_default: true)
        another_framework.remove_via_api!
      end

      it(
        'shows the compliance framework for each project',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396600'
      ) do
        subgroup.sandbox.visit!
        Page::Group::Menu.perform(&:click_compliance_report_link)
        QA::EE::Page::Group::Compliance::Show.perform do |report|
          report.click_frameworks_tab

          aggregate_failures do
            report.project_row(top_level_project) do |project|
              expect(project).to have_name(top_level_project.name)
              expect(project).to have_path(top_level_project.full_path)
              expect(project).to have_framework(default_compliance_framework.name)
              expect(project).to have_default_framework_badge
            end

            report.project_row(subgroup_project) do |project|
              expect(project).to have_name(subgroup_project.name)
              expect(project).to have_path(subgroup_project.full_path)
              expect(project).to have_framework(another_framework.name)
              expect(project).not_to have_default_framework_badge
            end

            report.project_row(project_without_framework) do |project|
              expect(project).to have_name(project_without_framework.name)
              expect(project).to have_path(project_without_framework.full_path)
              expect(project).not_to have_framework
            end
          end
        end
      end
    end
  end
end
