# frozen_string_literal: true

module QA
  module EE
    module Page
      module Main
        class Banner < QA::Page::Base
          view 'ee/app/helpers/ee/application_helper.rb' do
            element :read_only_message, 'You are on a secondary, %{b_open}read-only%{b_close} Geo site.' # rubocop:disable QA/ElementWithPattern
          end

          def has_secondary_read_only_banner?
            page.has_text?('You are on a secondary, read-only Geo site.')
          end
        end
      end
    end
  end
end
