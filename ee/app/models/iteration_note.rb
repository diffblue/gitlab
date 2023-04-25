# frozen_string_literal: true

class IterationNote < ::SyntheticNote
  attr_accessor :iteration

  def self.from_event(event, resource: nil, resource_parent: nil)
    attrs = note_attributes('iteration', event, resource, resource_parent).merge(iteration: event.iteration)

    IterationNote.new(attrs)
  end

  def note_html
    @note_html ||= Banzai::Renderer.cacheless_render_field(self, :note, { group: group, project: project })
  end

  private

  def note_text(html: false)
    reference = iteration&.to_reference(resource_parent, format: :id)
    event.remove? ? "removed iteration #{reference}" : "changed iteration to #{reference}"
  end
end
