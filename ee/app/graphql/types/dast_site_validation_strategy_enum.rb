# frozen_string_literal: true

module Types
  class DastSiteValidationStrategyEnum < BaseEnum
    value 'TEXT_FILE', description: 'Text file validation.', value: 'text_file'
    value 'HEADER', description: 'Header validation.', value: 'header'
    value 'META_TAG', description: 'Meta tag validation.', value: 'meta_tag'
  end
end
