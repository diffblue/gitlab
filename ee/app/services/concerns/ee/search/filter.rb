# frozen_string_literal: true

module EE
  module Search
    module Filter
      extend ::Gitlab::Utils::Override

      private

      override :filters
      def filters
        super.merge(language: params[:language], labels: params[:labels])
      end
    end
  end
end
