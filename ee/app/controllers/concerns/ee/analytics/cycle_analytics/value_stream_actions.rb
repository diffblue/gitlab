# frozen_string_literal: true

module EE
  module Analytics
    module CycleAnalytics
      module ValueStreamActions
        extend ActiveSupport::Concern

        extend ::Gitlab::Utils::Override

        def index
          return super unless ::Gitlab::Analytics::CycleAnalytics.licensed?(namespace)

          render json: ::Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(value_streams)
        end

        def new
          render :new
        end

        def show
          render json: ::Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(value_stream)
        end

        def edit
          value_stream

          render :edit
        end

        def create
          result = ::Analytics::CycleAnalytics::ValueStreams::CreateService.new(
            namespace: namespace,
            params: create_params,
            current_user: current_user).execute

          handle_value_stream_result result
        end

        def update
          result = ::Analytics::CycleAnalytics::ValueStreams::UpdateService.new(
            namespace: namespace,
            params: update_params,
            current_user: current_user,
            value_stream: value_stream).execute

          handle_value_stream_result result
        end

        def handle_value_stream_result(result)
          if result.success?
            render json: serialize_value_stream(result), status: result.http_status
          else
            render(
              json: {
                message: result.message,
                payload: { errors: serialize_value_stream_error(result) }
              },
              status: result.http_status
            )
          end
        end

        def destroy
          value_stream.destroy

          render json: {}, status: :ok
        end

        private

        def authorize
          # Special case, project-level index action is allowed without license
          return super if action_name.eql?("index") && namespace.is_a?(::Namespaces::ProjectNamespace)

          render_404 unless ::Gitlab::Analytics::CycleAnalytics.licensed?(namespace) &&
            ::Gitlab::Analytics::CycleAnalytics.allowed?(current_user, namespace)
        end

        def create_params
          params.require(:value_stream).permit(:name, stages: stage_create_params)
        end

        def update_params
          params.require(:value_stream).permit(:name, stages: stage_update_params)
        end

        def stage_create_params
          [
            :name,
            :start_event_identifier,
            :start_event_label_id,
            :end_event_identifier,
            :end_event_label_id,
            :custom,
            {
              start_event: [:identifier, :label_id],
              end_event: [:identifier, :label_id]
            }
          ]
        end

        def stage_update_params
          stage_create_params + [:id]
        end

        def value_streams
          @value_streams ||= namespace.value_streams.preload_associated_models
        end

        def serialize_value_stream(result)
          ::Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(result.payload[:value_stream])
        end

        def serialize_value_stream_error(result)
          ::Analytics::CycleAnalytics::ValueStreamErrorsSerializer.new(result.payload[:value_stream])
        end

        def value_stream
          @value_stream ||= namespace.value_streams.find(params[:id])
        end

        def load_stage_events
          @stage_events ||= begin
            selectable_events = ::Gitlab::Analytics::CycleAnalytics::StageEvents.selectable_events
            ::Analytics::CycleAnalytics::EventEntity.represent(selectable_events)
          end
        end
      end
    end
  end
end
