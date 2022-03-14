# frozen_string_literal: true

module Security
  class TrainingUrlsFinder
    def initialize(project, identifier_external_ids)
      @project = project
      @identifier_external_ids = identifier_external_ids
    end

    def execute
      return [] if identifier_external_ids.blank?

      security_training_urls(identifier_external_ids)
    end

    private

    attr_reader :project, :identifier_external_ids

    def security_training_urls(identifier_external_ids)
      [].tap do |content_urls|
        training_providers.each do |provider|
          identifier_external_ids.each do |identifier_external_id|
            class_name = "::Security::TrainingProviders::#{provider.name.delete(' ')}UrlFinder".safe_constantize
            content_url = class_name.new(project, provider, identifier_external_id).execute if class_name
            content_urls << content_url if content_url
          end
        end
      end
    end

    def training_providers
      ::Security::TrainingProvider.for_project(project, only_enabled: true).ordered_by_is_primary_desc
    end
  end
end
