# frozen_string_literal: true

module Mutations
  module QualityManagement
    module TestCases
      class Create < BaseMutation
        graphql_name 'CreateTestCase'

        include FindsProject

        authorize :create_test_case

        argument :title, GraphQL::Types::String,
                 required: true,
                 description: 'Test case title.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'Test case description.'

        argument :label_ids,
                 [GraphQL::Types::ID],
                 required: false,
                 description: 'IDs of labels to be added to the test case.'

        argument :project_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Project full path to create the test case in.'

        argument :confidential, GraphQL::Types::Boolean,
                 required: false,
                 description: 'Sets the test case confidentiality.'

        field :test_case, Types::IssueType,
              null: true,
              description: 'Test case created.'

        def resolve(args)
          project_path = args.delete(:project_path)
          project = authorized_find!(project_path)

          result = ::QualityManagement::TestCases::CreateService.new(
            project,
            context[:current_user],
            params: args
          ).execute

          {
            test_case: result.success? ? result[:issue] : nil,
            errors: result.errors
          }
        end
      end
    end
  end
end
