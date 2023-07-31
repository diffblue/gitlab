# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    # This class serializes errors from the ValueStream models and also includes errors from the stages relation.
    #
    # The ValueStream model uses accepts_nested_attributes_for when receiving stages (has many). The error
    # messages will be mapped to the respective form fields on the frontend. To do so, the serializer adds the
    # index of the stage (index from the incoming stages array) object in the response.
    #
    # Example error object:
    #
    # {
    #   name: ["can't be blank"],
    #   stages: {
    #     "1": {
    #       name: ["can't be blank"]
    #     }
    #   }
    class ValueStreamErrorsSerializer
      STAGE_ATTRIBUTE_REGEX = /stages\[(\d+)\]\.(.+)/

      def initialize(value_stream)
        @value_stream = value_stream
      end

      def as_json(options = {})
        value_stream.errors.messages.each_with_object({}) do |(attribute, messages), errors|
          # Parse out the indexed stage errors: "stages[1].name"
          if attribute.to_s.start_with?('stages[')
            attribute.match(STAGE_ATTRIBUTE_REGEX) do |matchdata|
              index, stage_attribute_name = matchdata.captures
              index = Integer(index)

              errors['stages'] ||= {}
              errors['stages'][index] ||= {}
              errors['stages'][index][stage_attribute_name] = messages
            end
          else
            errors[attribute.to_s] = messages
          end
        end
      end

      private

      attr_reader :value_stream
    end
  end
end
