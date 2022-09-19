# frozen_string_literal: true

module QA
  module EE
    module Resource
      class GroupIteration < QA::Resource::Base
        include Support::Dates

        attribute :group do
          QA::Resource::Group.fabricate_via_api! do |group|
            group.path = "group-to-test-iterations-#{SecureRandom.hex(8)}"
          end
        end

        attributes :id,
                   :iid,
                   :description,
                   :title,
                   :state,
                   :start_date,
                   :due_date,
                   :created_at,
                   :updated_at,
                   :cadence

        def initialize
          @start_date = current_date_yyyy_mm_dd
          @due_date = next_month_yyyy_mm_dd
          @title = "Iteration-#{SecureRandom.hex(8)}"
          @description = "This is a test iteration."
        end

        def fabricate!
          @cadence ||= QA::EE::Resource::GroupCadence.fabricate_via_browser_ui! do |cadence|
            cadence.group = group
          end

          @cadence.group.visit!

          QA::Page::Group::Menu.perform(&:go_to_group_iterations)

          QA::EE::Page::Group::Iteration::Cadence::Index.perform do |cadence_list|
            cadence_list.click_new_iteration_button(@cadence.title)
          end

          QA::EE::Page::Group::Iteration::New.perform do |iteration_page|
            iteration_page.fill_title(@title)
            iteration_page.fill_description(@description)
            iteration_page.fill_start_date(@start_date)
            iteration_page.fill_due_date(@due_date)
            iteration_page.click_create_iteration_button
          end
        end

        # Iteration attributes
        #
        # @return [String]
        def gql_attributes
          @gql_attributes ||= <<~GQL
            id
            iid
            description
            title
            state
            startDate
            dueDate
            createdAt
            updatedAt
            webUrl
          GQL
        end

        # Path for fetching iteration
        #
        # @return [String]
        def api_get_path
          "/graphql"
        end

        # Fetch iteration
        #
        # @return [Hash]
        def api_get
          process_api_response(
            api_post_to(
              api_get_path,
              <<~GQL
                query {
                  iteration(id: "gid://gitlab/Iteration/#{id}") {
                    #{gql_attributes}
                  }
                }
              GQL
            )
          )
        end

        # Path to create iteration
        #
        # @return [String]
        def api_post_path
          "/graphql"
        end

        # Graphql mutation for iteration creation
        #
        # @return [String]
        def api_post_body
          <<~GQL
            mutation {
              createIteration(input: {
                groupPath: "#{group.full_path}"
                title: "#{@title}"
                description: "#{@description}"
                startDate: "#{@start_date}"
                dueDate: "#{@due_date}"
                }) {
                iteration {
                  #{gql_attributes}
                }
                errors
              }
            }
          GQL
        end

        protected

        # Return subset of fields for comparing iterations
        #
        # @return [Hash]
        def comparable
          reload! unless api_response

          api_response.slice(
            :description,
            :state,
            :due_date,
            :start_date
          )
        end
      end
    end
  end
end
