# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module ProtectedTags
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'app/assets/javascripts/protected_tags/protected_tag_create.js' do
                  element :allowed_to_create_dropdown
                end
              end
            end
          end
        end
      end
    end
  end
end
