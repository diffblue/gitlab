# frozen_string_literal: true

module Security
  class TrainingUrlsFinder
    def initialize(vulnerability)
      @vulnerability = vulnerability
    end

    def execute
      cwe_identifiers = @vulnerability.identifiers&.with_external_type('cwe')
      return [] if cwe_identifiers.blank?

      security_training_urls(cwe_identifiers)
    end

    private

    def security_training_urls(cwe_identifiers)
      [].tap do |content_urls|
        training_providers.each do |provider|
          cwe_identifiers.each do |identifier|
            class_name = "::Security::TrainingProviders::#{provider.name.delete(' ')}UrlFinder".safe_constantize
            content_url = class_name.new(provider, identifier).execute if class_name
            content_urls << content_url if content_url
          end
        end
      end
    end

    def training_providers
      ::Security::TrainingProvider.for_project(@vulnerability.project, only_enabled: true).ordered_by_is_primary_desc
    end
  end
end
