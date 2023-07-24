# frozen_string_literal: true

module EE
  module Projects
    module ImportExport
      module ProjectExportPresenter
        extend ::Gitlab::Utils::DelegatorOverride

        delegator_override :approval_rules
        def approval_rules
          project.approval_rules.exportable
        end
      end
    end
  end
end
