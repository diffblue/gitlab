# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Geo
        class Node < QA::Resource::Base
          attr_accessor :name
          attr_accessor :address

          def fabricate!
            QA::Page::Main::Login.perform(&:sign_in_using_credentials)
            QA::Page::Main::Menu.perform(&:go_to_admin_area)
            QA::Page::Admin::Menu.perform(&:click_geo_menu_link)
            EE::Page::Admin::Geo::Nodes::Show.perform(&:new_node!)

            EE::Page::Admin::Geo::Nodes::New.perform do |new_page|
              raise ArgumentError if @name.nil? || @address.nil?

              new_page.set_site_name(@name)
              new_page.set_site_address(@address)
              new_page.add_site!
            end

            QA::Page::Main::Menu.perform(&:sign_out)
          end
        end
      end
    end
  end
end
