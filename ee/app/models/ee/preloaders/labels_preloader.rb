# frozen_string_literal: true

module EE
  module Preloaders
    module LabelsPreloader
      extend ::Gitlab::Utils::Override

      override :preload_all
      def preload_all
        super

        ActiveRecord::Associations::Preloader.new(
          records: labels.select { |l| l.is_a? GroupLabel },
          associations: { group: [:ip_restrictions, :saml_provider] }
        ).call
      end
    end
  end
end
