# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Wiki
          class Edit < QA::Page::Base
            include QA::Page::Component::WikiPageForm
            include QA::Page::Component::WikiSidebar
            include QA::Page::Component::ContentEditor
          end
        end
      end
    end
  end
end
