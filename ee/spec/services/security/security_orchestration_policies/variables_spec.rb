# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies do
  include ::UpdateOrchestrationPolicyConfiguration

  let(:group) { create(:group) }

  let(:project) do
    create(:project,
           :custom_repo,
           group: group,
           files: { ".gitlab-ci.yml" => gitlab_ci_yml })
  end

  let(:policy_management_project) do
    create(:project,
           :custom_repo,
           files: { ".gitlab/security-policies/policy.yml" => policy_yml })
  end

  let(:policy_configuration) do
    create(:security_orchestration_policy_configuration,
           security_policy_management_project: policy_management_project,
           project: project)
  end

  let(:current_user) { project.creator }
  let(:builds) { project.builds.pluck(:name) }

  let(:gitlab_ci_yml) { "" }
  let(:policy_yml) { "" }

  before do
    stub_licensed_features(security_orchestration_policies: true, security_on_demand_scans: true)
    project.add_owner(current_user)
    policy_management_project.repository.create_branch("main", policy_management_project.default_branch)
  end

  describe "scheduled scans" do
    let(:policy_yml) do
      <<~YML
      scan_execution_policy:
      - name: Test
        description: ''
        enabled: true
        actions:
        - scan: container_scanning
        - scan: sast
        rules:
        - type: schedule
          cadence: '0 10 * * *'
          branches:
          - "*"
      YML
    end

    before do
      project.repository.commit_files(current_user,
                                      message: "Add Gemfile in order to run brakeman-sast",
                                      branch_name: "master",
                                      actions: [{ action: :create, file_path: "Gemfile", contents: "" }])

      update_policy_configuration(policy_configuration)

      policy_configuration.rule_schedules.reload.each do |schedule|
        service = Security::SecurityOrchestrationPolicies::RuleScheduleService.new(container: project,
                                                                                   current_user: current_user)
        service.execute(schedule)
      end

      project.all_pipelines.flat_map(&:bridges).each do |bridge|
        Ci::CreateDownstreamPipelineService.new(project, current_user).execute(bridge)
      end
    end

    describe ".gitlab-ci.yml with top-level YAML variables" do
      let(:gitlab_ci_yml) do
        <<~YML
      variables:
        CONTAINER_SCANNING_DISABLED: 'true'
        SAST_DISABLED: 'true'
      YML
      end

      specify do
        expect(builds).to contain_exactly("container-scanning-0", "brakeman-sast")
      end
    end

    describe "project-level CI variables" do
      before do
        project.variables.create!([{ key: "CONTAINER_SCANNING_DISABLED", value: "true" },
                                   { key: "SAST_DISABLED", value: "true" }])
      end

      specify do
        expect(builds).to contain_exactly("container-scanning-0", "brakeman-sast")
      end
    end

    describe "group-level CI variables" do
      before do
        group.variables.create!([{ key: "CONTAINER_SCANNING_DISABLED", value: "true" },
                                 { key: "SAST_DISABLED", value: "true" }])
      end

      specify do
        expect(builds).to contain_exactly("container-scanning-0", "brakeman-sast")
      end
    end
  end

  describe "pipeline scans" do
    include ::UpdateOrchestrationPolicyConfiguration

    let(:gitlab_ci_yml) do
      <<~YML
      variables:
        CONTAINER_SCANNING_DISABLED: 'true'
        SAST_DISABLED: 'true'
      dummy_job:
        stage: test
        script: ":"
      skipped_job:
        script: ":"
        rules:
          - if: $CONTAINER_SCANNING_DISABLED
            when: never
      YML
    end

    let(:policy_yml) do
      <<~YML
      scan_execution_policy:
      - name: Test
        description: ''
        enabled: true
        actions:
        - scan: container_scanning
        - scan: sast
        rules:
        - type: pipeline
          branches:
          - "*"
      YML
    end

    before do
      project.repository.commit_files(current_user,
                                      message: "Add Gemfile in order to run brakeman-sast",
                                      branch_name: "master",
                                      actions: [{ action: :create, file_path: "Gemfile", contents: "" }])

      update_policy_configuration(policy_configuration)

      Ci::CreatePipelineService.new(project, current_user, ref: project.repository.root_ref).execute(:web)

      project.all_pipelines.flat_map(&:bridges).each do |bridge|
        Ci::CreateDownstreamPipelineService.new(project, current_user).execute(bridge)
      end
    end

    specify do
      expect(builds).to contain_exactly("dummy_job", "container-scanning-0", "brakeman-sast")
    end

    describe "project-level CI variables" do
      before do
        project.variables.create!([{ key: "CONTAINER_SCANNING_DISABLED", value: "true" },
                                   { key: "SAST_DISABLED", value: "true" }])
      end

      specify do
        expect(builds).to contain_exactly("dummy_job", "container-scanning-0", "brakeman-sast")
      end
    end

    describe "group-level CI variables" do
      before do
        group.variables.create!([{ key: "CONTAINER_SCANNING_DISABLED", value: "true" },
                                 { key: "SAST_DISABLED", value: "true" }])
      end

      specify do
        expect(builds).to contain_exactly("dummy_job", "container-scanning-0", "brakeman-sast")
      end
    end
  end
end
