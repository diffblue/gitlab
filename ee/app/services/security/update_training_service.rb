# frozen_string_literal: true

module Security
  class UpdateTrainingService < BaseService
    def initialize(project, params)
      @project = project
      @params = params
    end

    def execute
      return error('Updating security training failed! Provider not found.') unless provider

      delete? ? delete_training : upsert_training

      service_response
    end

    private

    def primary?
      params[:is_primary] == true
    end

    def delete?
      params[:is_enabled] == false
    end

    def delete_training
      training&.destroy
    end

    def upsert_training
      training.transaction do
        project.security_trainings.update_all(is_primary: false) if primary?

        training.update(is_primary: primary?)
      end
    end

    def training
      @training ||= project.security_trainings.find_or_initialize_by(provider: provider) # rubocop: disable CodeReuse/ActiveRecord
    end

    def provider
      @provider ||= begin
        GlobalID::Locator.locate(params[:provider_id])
      rescue ActiveRecord::RecordNotFound
      end
    end

    def service_response
      if training.errors.any?
        error('Updating security training failed!', pass_back: { training: training })
      else
        success(training: training)
      end
    end
  end
end
