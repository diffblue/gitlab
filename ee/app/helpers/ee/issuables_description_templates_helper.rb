# frozen_string_literal: true

module EE
  module IssuablesDescriptionTemplatesHelper
    extend ::Gitlab::Utils::Override

    override :issuable_templates_names
    def issuable_templates_names(issuable, include_inherited_templates = false)
      return super unless include_inherited_templates

      all_templates = issuable_templates(ref_project, issuable.to_ability_name)
      all_templates.values.flatten.map { |tpl| tpl[:name] }.compact.uniq
    end
  end
end
