# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module ValueStreams
      class CreateService
        include Gitlab::Allowable

        def initialize(namespace:, params:, current_user:, value_stream: ::Analytics::CycleAnalytics::ValueStream.new(namespace: namespace))
          @value_stream = value_stream
          @namespace = namespace
          @params = process_params(params.dup.to_h)
          @current_user = current_user
        end

        def execute
          error = authorize!
          return error if error

          value_stream.assign_attributes(params)

          if value_stream.save
            ServiceResponse.success(message: nil, payload: { value_stream: value_stream }, http_status: success_http_status)
          else
            # workaround to properly index nested stage errors
            # More info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51623#note_490919557
            value_stream.valid?(:context_to_validate_all_stages)
            ServiceResponse.error(message: 'Invalid parameters', payload: { errors: value_stream.errors, value_stream: value_stream }, http_status: :unprocessable_entity)
          end
        end

        private

        attr_reader :value_stream, :namespace, :params, :current_user

        def process_params(raw_params)
          raw_params[:stages_attributes] = raw_params.delete(:stages) || []
          raw_params[:stages_attributes].map! { |attrs| build_stage_attributes(attrs) }

          remove_in_memory_stage_ids!(raw_params[:stages_attributes])
          set_relative_positions!(raw_params[:stages_attributes])

          raw_params
        end

        def build_stage_attributes(stage_attributes)
          stage_attributes[:namespace] = namespace
          return stage_attributes if Gitlab::Utils.to_boolean(stage_attributes[:custom])

          # if we're persisting a default stage, ignore the user provided attributes and use our attributes
          use_default_stage_params(stage_attributes)
        end

        def use_default_stage_params(stage_attributes)
          default_stage_attributes = Gitlab::Analytics::CycleAnalytics::DefaultStages.find_by_name!(stage_attributes[:name].to_s.downcase)
          stage_attributes.merge(default_stage_attributes)
        end

        def success_http_status
          :created
        end

        def authorize!
          unless ::Gitlab::Analytics::CycleAnalytics.allowed?(current_user, namespace)
            ServiceResponse.error(message: 'Forbidden', http_status: :forbidden, payload: { errors: nil })
          end
        end

        def set_relative_positions!(stages_attributes)
          increment = (Gitlab::RelativePositioning::MAX_POSITION - Gitlab::RelativePositioning::START_POSITION).fdiv(stages_attributes.size + 1).floor
          stages_attributes.each_with_index do |stage_attribute, i|
            stage_attribute[:relative_position] = increment * i
          end
        end

        def remove_in_memory_stage_ids!(stage_attributes)
          stage_attributes.each do |stage_attribute|
            if Gitlab::Analytics::CycleAnalytics::DefaultStages.names.include?(stage_attribute[:id])
              stage_attribute.delete(:id)
            end
          end
        end
      end
    end
  end
end
