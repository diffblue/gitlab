# frozen_string_literal: true

module Vulnerabilities
  module LinkTypeEnum
    extend DeclarativeEnum

    key :link_type
    name 'VulnerabilityExternalIssueLinkType'
    description 'The type of the external issue link related to a vulnerability'

    define do
      created value: 1, description: 'Created link type.'
    end
  end
end
