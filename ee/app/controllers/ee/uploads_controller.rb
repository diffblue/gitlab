# frozen_string_literal: true

module EE
  module UploadsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    EE_MODEL_CLASSES = {
      'issuable_metric_image' => IssuableMetricImage
    }.freeze

    class_methods do
      extend ::Gitlab::Utils::Override

      override :model_classes
      def model_classes
        super.merge(EE_MODEL_CLASSES)
      end
    end

    override :authorized?
    def authorized?
      case model
      when IssuableMetricImage
        can?(current_user, :read_issuable_metric_image, model)
      else
        super
      end
    end
  end
end
