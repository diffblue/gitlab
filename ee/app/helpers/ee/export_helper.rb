# frozen_string_literal: true

module EE
  module ExportHelper
    extend ::Gitlab::Utils::Override

    override :group_export_descriptions
    def group_export_descriptions
      super + [_('Epics'), _('Events'), _('Group wikis')]
    end
  end
end
