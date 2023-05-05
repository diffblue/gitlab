# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module MirroringRepositories
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/views/projects/mirrors/_mirror_repos_form.html.haml' do
                  element :mirror_direction_field
                end

                view 'ee/app/views/projects/mirrors/_table_pull_row.html.haml' do
                  element :mirror_last_update_at_content
                  element :mirror_repository_url_content
                  element :mirrored_repository_row_container
                  element :update_now_button
                  element :copy_public_key_button
                end
              end
            end
          end
        end
      end
    end
  end
end
