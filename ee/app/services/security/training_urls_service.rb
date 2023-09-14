# frozen_string_literal: true

module Security
  class TrainingUrlsService
    EXTENSION_LANGUAGE_MAP = {
      'jsp' => 'java',
      'jspx' => 'java',
      'py' => 'python',
      'scala' => 'scala',
      'sc' => 'scala',
      'js' => 'javascript',
      'ts' => 'typescript',
      'php' => 'php',
      'rb' => 'ruby',
      'go' => 'go',
      'kt' => 'kotlin',
      'kts' => 'kotlin',
      'ktm' => 'kotlin',
      'cs' => 'csharp'
    }.freeze

    def initialize(project, identifier_external_ids, filename = nil)
      @project = project
      @identifier_external_ids = identifier_external_ids
      @filename = filename
      @language = language_from_filename
    end

    def execute
      return [] if identifier_external_ids.blank?

      security_training_urls(identifier_external_ids)
    end

    private

    attr_reader :project, :identifier_external_ids, :language, :filename

    def security_training_urls(identifier_external_ids)
      [].tap do |content_urls|
        training_providers.each do |provider|
          identifier_external_ids.each do |identifier_external_id|
            class_name = "::Security::TrainingProviders::#{provider.name.delete(' ')}UrlService".safe_constantize
            content_url = class_name.new(project, provider, identifier_external_id, language).execute if class_name
            content_urls << content_url if content_url
          end
        end
      end
    end

    def training_providers
      ::Security::TrainingProvider.for_project(project, only_enabled: true).ordered_by_is_primary_desc
    end

    def language_from_filename
      EXTENSION_LANGUAGE_MAP[filename.split(".").last] if filename
    end
  end
end
