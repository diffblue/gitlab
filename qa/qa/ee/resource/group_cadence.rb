# frozen_string_literal: true

module QA
  module EE
    module Resource
      class GroupCadence < QA::Resource::Base
        include Support::Dates

        attr_accessor :title, :group

        attribute :group do
          QA::Resource::Group.fabricate_via_api! do |group|
            group.path = "group-to-test-iterations-#{SecureRandom.hex(8)}"
          end
        end

        attribute :id
        attribute :start_date
        attribute :description
        attribute :title

        def initialize
          @start_date = current_date_yyyy_mm_dd
          @description = "This is a test cadence."
          @title = "Iteration Cadence #{SecureRandom.hex(8)}"
          @automatic = false
        end

        def fabricate!
          group.visit!

          QA::Page::Group::Menu.perform(&:go_to_group_iterations)

          QA::EE::Page::Group::Iteration::Cadence::Index.perform(&:click_new_iteration_cadence_button)

          QA::EE::Page::Group::Iteration::Cadence::New.perform do |new|
            new.fill_title(@title)
            new.uncheck_automatic_scheduling
            new.fill_start_date(@start_date)
            new.click_create_iteration_cadence_button
          end
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
                automatic: #{@automatic}
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
