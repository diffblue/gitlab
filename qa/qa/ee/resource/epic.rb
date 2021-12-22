# frozen_string_literal: true

module QA
  module EE
    module Resource
      class Epic < QA::Resource::Base
        attributes :id,
                   :iid,
                   :title,
                   :description,
                   :labels,
                   :parent_id,
                   :start_date_is_fixed,
                   :start_date_fixed,
                   :due_date_is_fixed,
                   :due_date_fixed,
                   :confidential,
                   :author,
                   :start_date,
                   :due_date,
                   :start_date_from_milestones,
                   :due_date_from_milestones

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

        def api_award_emoji_path
          "#{api_get_path}/award_emoji"
        end

        def api_post_body
          {
            title: title,
            labels: @labels,
            start_date_is_fixed: @start_date_is_fixed,
            start_date_fixed: @start_date_fixed,
            due_date_is_fixed: @due_date_is_fixed,
            due_date_fixed: @due_date_fixed,
            confidential: @confidential,
            parent_id: @parent_id
          }
        end

        # Create new award emoji
        #
        # @param [String] name
        # @return [Hash]
        def award_emoji(name)
          response = post(::QA::Runtime::API::Request.new(api_client, api_award_emoji_path).url, { name: name })

          parse_body(response)
        end

        protected

        # Return subset of fields for comparing epics
        #
        # @return [Hash]
        def comparable
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
