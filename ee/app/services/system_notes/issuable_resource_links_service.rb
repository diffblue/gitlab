# frozen_string_literal: true

module SystemNotes
  class IssuableResourceLinksService < ::SystemNotes::BaseService
    def issuable_resource_link_added(resource_link)
      link_type = resource_link.general? ? 'resource' : resource_link.link_type.capitalize
      body = format(_("added a %{link_type} link"), link_type: link_type)
      create_note(NoteSummary.new(noteable, project, author, body, action: 'relate'))
    end

    def issuable_resource_link_removed(resource_link)
      link_type = resource_link.general? ? 'resource' : resource_link.link_type.capitalize
      body = format(_("removed a %{link_type} link"), link_type: link_type)
      create_note(NoteSummary.new(noteable, project, author, body, action: 'relate'))
    end
  end
end
