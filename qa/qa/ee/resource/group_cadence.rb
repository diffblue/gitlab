# frozen_string_literal: true

module QA
  module EE
    module Resource
      class GroupCadence < QA::Resource::Base
        include Support::Dates

        attribute :group do
          QA::Resource::Group.fabricate_via_api! do |group|
            group.path = "group-to-test-iteration-cadences-#{SecureRandom.hex(8)}"
          end
        end

        attribute :id
        attribute :description
        attribute :duration
        attribute :upcoming_iterations
        attribute :start_date
        attribute :title

        def initialize
          @start_date = current_date_yyyy_mm_dd
          @description = "This is a test cadence."
          @title = "Iteration Cadence #{SecureRandom.hex(8)}"
          @duration = 2
          @upcoming_iterations = 2
        end

        def fabricate!
          group.visit!

          QA::Page::Group::Menu.perform(&:go_to_group_iterations)

          QA::EE::Page::Group::Iteration::Cadence::Index.perform(&:click_new_iteration_cadence_button)

          QA::EE::Page::Group::Iteration::Cadence::New.perform do |new|
            new.fill_title(@title)
            new.fill_start_date(@start_date)
            new.fill_duration(@duration)
            new.fill_upcoming_iterations(@upcoming_iterations)
            new.click_create_iteration_cadence_button
          end
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "gid://gitlab/Cadence/#{id}"
        end

        def api_post_path
          "/graphql"
        end

        def api_post_body
          <<~GQL
            mutation {
              iterationCadenceCreate(input: {
                groupPath: "#{group.full_path}"
                title: "#{@title}"
                description: "#{@description}"
                startDate: "#{@start_date}"
                iterationsInAdvance: #{@upcoming_iterations}
                durationInWeeks: #{@duration}
                automatic: true
                active: true
                }) {
                iterationCadence {
                  id
                  title
                  description
                  startDate
                }
                errors
              }
            }
          GQL
        end
      end
    end
  end
end
