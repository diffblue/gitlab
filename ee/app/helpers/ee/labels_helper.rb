# frozen_string_literal: true

module EE
  module LabelsHelper
    extend ActiveSupport::Concern

    prepended do
      singleton_class.prepend self
    end

    def render_colored_label(label, suffix: '')
      return super unless label.scoped_label?

      render_label_text(
        label.scoped_label_key,
        css_class: "gl-label-text #{label.text_color_class}",
        bg_color: label.color
      ) + render_label_text(
        label.scoped_label_value,
        css_class: "gl-label-text-scoped",
        suffix: suffix
      )
    end

    def wrap_label_html(label_html, small:, label:)
      return super unless label.scoped_label?

      wrapper_classes = %w(gl-label gl-label-scoped)
      wrapper_classes << 'gl-label-sm' if small

      border_width = small ? '1px' : '2px'

      %(<span class="#{wrapper_classes.join(' ')}" style="--label-inset-border: inset 0 0 0 #{border_width} #{html_escape(label.color)}; color: #{html_escape(label.color)}">#{label_html}</span>).html_safe
    end

    def label_tooltip_title(label)
      tooltip = super
      tooltip = %(<span class='font-weight-bold scoped-label-tooltip-title'>Scoped label</span><br>#{tooltip}) if label.scoped_label?

      tooltip
    end

    def label_dropdown_data(edit_context, opts = {})
      scoped_labels_fields = {
        scoped_labels: edit_context&.feature_available?(:scoped_labels)&.to_s
      }

      return super.merge(scoped_labels_fields) unless edit_context.is_a?(Group)

      {
        toggle: "dropdown",
        field_name: opts[:field_name] || "label_name[]",
        show_no: "true",
        show_any: "true",
        group_id: edit_context&.try(:id)
      }.merge(scoped_labels_fields, opts)
    end

    def labels_function_introduction
      return super unless @group&.feature_available?(:epics)

      _('Labels can be applied to issues, merge requests, and epics. Group labels are available for any project within the group.')
    end
  end
end
