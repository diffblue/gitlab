# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Environments query', feature_category: :continuous_delivery do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, :repository, group: group) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:guest) { create(:user).tap { |u| project.add_guest(u) } }

  subject { post_graphql(query, current_user: user) }

  let(:user) { developer }

  context 'with protected environments' do
    let!(:protected_environment) do
      create(:protected_environment, name: environment.name, project: project,
                                     deploy_access_levels: deploy_access_levels, approval_rules: approval_rules)
    end

    let(:deploy_access_levels) { [build(:protected_environment_deploy_access_level, :maintainer_access)] }
    let(:approval_rules) { [build(:protected_environment_approval_rule, :developer_access)] }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            environment(name: "#{environment.name}") {
              protectedEnvironments {
                nodes {
                  name
                  project {
                    name
                  }
                  group {
                    name
                  }
                  deployAccessLevels {
                    nodes {
                      #{authorizable_attributes}
                    }
                  }
                  approvalRules {
                    nodes {
                      requiredApprovals
                      #{authorizable_attributes}
                    }
                  }
                  requiredApprovalCount
                }
              }
            }
          }
        }
      )
    end

    let(:authorizable_attributes) do
      %(
        group {
          name
        }
        user {
          name
        }
        accessLevel {
          stringValue
        }
      )
    end

    it 'returns protected environment attributes', :aggregate_failures do
      subject

      protected_environments_data = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes)
      expect(protected_environments_data.count).to eq(1)

      protected_environment_data = protected_environments_data.first
      expect(protected_environment_data['name']).to eq(protected_environment.name)
      expect(protected_environment_data['project']['name']).to eq(protected_environment.project.name)
      expect(protected_environment_data['group']).to be_nil
    end

    it 'returns deploy access levels', :aggregate_failures do
      subject

      deploy_access_levels_data = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes, 0,
                                                  :deployAccessLevels, :nodes)
      expect(deploy_access_levels_data.count).to eq(1)

      deploy_access_level_data = deploy_access_levels_data.first
      expect(deploy_access_level_data['group']).to be_nil
      expect(deploy_access_level_data['user']).to be_nil
      expect(deploy_access_level_data['accessLevel']['stringValue']).to eq('MAINTAINER')
    end

    it 'returns approval rules', :aggregate_failures do
      subject

      approval_rules_data = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes, 0,
                                            :approvalRules, :nodes)
      expect(approval_rules_data.count).to eq(1)

      approval_rule_data = approval_rules_data.first
      expect(approval_rule_data['group']).to be_nil
      expect(approval_rule_data['user']).to be_nil
      expect(approval_rule_data['accessLevel']['stringValue']).to eq('DEVELOPER')
    end

    it 'returns unified approval setting', :aggregate_failures do
      subject

      required_approval_count = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes, 0,
                                                :requiredApprovalCount)
      expect(required_approval_count).to eq(0)
    end

    context 'when a specifc user is allowed to deploy' do
      let(:deploy_access_levels) { [build(:protected_environment_deploy_access_level, user: deployer)] }
      let(:deployer) { create(:user) }

      it 'returns deploy access levels', :aggregate_failures do
        subject

        deploy_access_level_data = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes, 0,
                                                   :deployAccessLevels, :nodes, 0)
        expect(deploy_access_level_data['group']).to be_nil
        expect(deploy_access_level_data['user']['name']).to eq(deployer.name)
        expect(deploy_access_level_data['accessLevel']).to be_nil
      end
    end

    context 'when a specifc user is allowed to approve' do
      let(:approval_rules) { [build(:protected_environment_approval_rule, user: approver)] }
      let(:approver) { create(:user) }

      it 'returns approval rules', :aggregate_failures do
        subject

        approval_rule_data = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes, 0,
                                             :approvalRules, :nodes, 0)
        expect(approval_rule_data['group']).to be_nil
        expect(approval_rule_data['user']['name']).to eq(approver.name)
        expect(approval_rule_data['accessLevel']).to be_nil
      end
    end

    context 'when a specifc group is allowed to deploy' do
      let(:deploy_access_levels) { [build(:protected_environment_deploy_access_level, group: deployer)] }
      let(:deployer) { create(:group) }

      it 'returns deploy access levels', :aggregate_failures do
        subject

        deploy_access_level_data = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes, 0,
                                                   :deployAccessLevels, :nodes, 0)
        expect(deploy_access_level_data['group']['name']).to eq(deployer.name)
        expect(deploy_access_level_data['user']).to be_nil
        expect(deploy_access_level_data['accessLevel']).to be_nil
      end
    end

    context 'when a specifc group is allowed to approve' do
      let(:approval_rules) { [build(:protected_environment_approval_rule, group: approver)] }
      let(:approver) { create(:group) }

      it 'returns approval rules', :aggregate_failures do
        subject

        approval_rule_data = graphql_data_at(:project, :environment, :protectedEnvironments, :nodes, 0,
                                             :approvalRules, :nodes, 0)
        expect(approval_rule_data['group']['name']).to eq(approver.name)
        expect(approval_rule_data['user']).to be_nil
        expect(approval_rule_data['accessLevel']).to be_nil
      end
    end

    context 'when fetching protected environments for multiple environments' do
      let!(:protected_environment) do
        create(:protected_environment,
          name: environment.name,
          project: project,
          deploy_access_levels: [build(:protected_environment_deploy_access_level, group: create(:group))],
          approval_rules: [build(:protected_environment_approval_rule, user: create(:user))])
      end

      let!(:protected_environment_2) do
        create(:protected_environment,
          name: environment_2.name,
          project: project,
          deploy_access_levels: [build(:protected_environment_deploy_access_level, group: create(:group))],
          approval_rules: [build(:protected_environment_approval_rule, user: create(:user))])
      end

      let(:environment_2) { create(:environment, project: project) }

      let(:multi_query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environments {
                nodes {
                  protectedEnvironments {
                    nodes {
                      name
                      project {
                        name
                      }
                      group {
                        name
                      }
                      deployAccessLevels {
                        nodes {
                          #{authorizable_attributes}
                        }
                      }
                      approvalRules {
                        nodes {
                          requiredApprovals
                          #{authorizable_attributes}
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        )
      end

      it 'avoids N+1 query issue' do
        baseline = ActiveRecord::QueryRecorder.new do
          run_with_clean_state(query, context: { current_user: user })
        end

        multi = ActiveRecord::QueryRecorder.new do
          run_with_clean_state(multi_query, context: { current_user: user })
        end

        # +1 for each protected environment to check if user has been banned from project
        expect(multi).not_to exceed_query_limit(baseline).with_threshold(1)
      end
    end

    context 'when user does not have access to the environment' do
      let(:user) { guest }

      it 'does not return protected environments' do
        subject

        expect(graphql_data_at(:project, :environment)).to be_nil
      end
    end
  end
end
