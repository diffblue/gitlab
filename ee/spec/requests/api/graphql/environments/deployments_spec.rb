# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments Deployments query', feature_category: :continuous_delivery do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:guest) { create(:user).tap { |u| project.add_guest(u) } }

  let(:user) { developer }

  subject { post_graphql(query, current_user: user) }

  context 'when requesting user permissions' do
    before_all do
      create_list(:deployment, 2, :blocked, environment: environment, project: project)
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            environment(name: "#{environment.name}") {
              deployments {
                nodes {
                  iid
                  userPermissions {
                    approveDeployment
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'limits the result', :aggregate_failures do
      subject

      expect_graphql_errors_to_include('"approveDeployment" field can be requested only ' \
                                       'for 1 DeploymentPermissions(s) at a time.')
    end
  end
end
