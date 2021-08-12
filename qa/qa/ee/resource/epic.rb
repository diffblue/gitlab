# frozen_string_literal: true

module QA
  module EE
    module Resource
      class Epic < QA::Resource::Base
        attributes :iid,
                   :title,
                   :description,
                   :start_date_is_fixed,
                   :start_date_fixed,
                   :due_date_is_fixed,
                   :due_date_fixed,
                   :confidential

        attribute :group do
          QA::Resource::Group.fabricate!
        end

        def initialize
          @start_date_is_fixed = false
          @due_date_is_fixed = false
          @confidential = false
        end

        def fabricate!
          group.visit!

          QA::Page::Group::Menu.perform(&:click_group_epics_link)

          QA::EE::Page::Group::Epic::Index.perform(&:click_new_epic)

          QA::EE::Page::Group::Epic::New.perform do |new_epic_page|
            new_epic_page.set_title(title)
            new_epic_page.enable_confidential_epic if @confidential
            new_epic_page.create_new_epic
          end
        end

        def api_get_path
          "/groups/#{CGI.escape(group.full_path)}/epics/#{iid}"
        end

        def api_post_path
          "/groups/#{CGI.escape(group.full_path)}/epics"
        end

        def api_post_body
          {
            title: @title,
            start_date_is_fixed: @start_date_is_fixed,
            start_date_fixed: @start_date_fixed,
            due_date_is_fixed: @due_date_is_fixed,
            due_date_fixed: @due_date_fixed,
            confidential: @confidential,
            parent_id: @parent_id
          }
        end

        # Object comparison
        #
        # @param [QA::EE::Resource::Epic] other
        # @return [Boolean]
        def ==(other)
          other.is_a?(Epic) && comparable_epic == other.comparable_epic
        end

        # Override inspect for a better rspec failure diff output
        #
        # @return [String]
        def inspect
          JSON.pretty_generate(comparable_epic)
        end

        protected

        # Return subset of fields for comparing epics
        #
        # @return [Hash]
        def comparable_epic
          reload! if api_response.nil?

          api_resource.slice(
            :title,
            :description,
            :state,
            :start_date_is_fixed,
            :start_date_fixed,
            :due_date_is_fixed,
            :due_date_fixed,
            :confidential,
            :labels,
            :upvotes,
            :downvotes
          )
        end
      end
    end
  end
end
