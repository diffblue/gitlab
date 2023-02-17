# frozen_string_literal: true

module Vulnerabilities
  module ExternalTypeEnum
    extend DeclarativeEnum

    key :external_type
    name 'VulnerabilityExternalType'
    description 'The external type of the vulnerability'

    define do
      jira value: 1
    end
  end
end
