# frozen_string_literal: true

module Dependencies
  class DestroyExportWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: true

    idempotent!
    feature_category :dependency_management

    def perform(dependency_list_export_id)
      dependency_list_export = Dependencies::DependencyListExport.find_by_id(dependency_list_export_id)
      dependency_list_export&.destroy!
    end
  end
end
