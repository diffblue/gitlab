# frozen_string_literal: true

module RequirementsManagement
  class PrepareImportCsvService < Import::PrepareService
    extend ::Gitlab::Utils::Override

    private

    override :worker
    def worker
      RequirementsManagement::ImportRequirementsCsvWorker
    end

    override :success_message
    def success_message
      _("Your requirements are being imported. Once finished, you'll receive a confirmation email.")
    end
  end
end
