# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallRotation
      class Base < BaseMutation
        MAXIMUM_PARTICIPANTS = 100
        TIME_FORMAT = /^(0\d|1\d|2[0-3]):[0-5]\d$/.freeze

        field :oncall_rotation,
              ::Types::IncidentManagement::OncallRotationType,
              null: true,
              description: 'On-call rotation.'

        authorize :admin_incident_management_oncall_schedule

        private

        def response(result)
          {
            oncall_rotation: result.payload[:oncall_rotation],
            errors: result.errors
          }
        end

        def find_object(project_path:, schedule_iid:, **args)
          project = Project.find_by_full_path(project_path)

          return unless project

          schedule = ::IncidentManagement::OncallSchedulesFinder.new(current_user, project, iid: schedule_iid).execute.first

          return unless schedule

          args = args.merge(id: args[:id].model_id)

          ::IncidentManagement::OncallRotationsFinder.new(current_user, project, schedule, args).execute.first
        end

        def parsed_params(schedule, participants, args)
          params = args.slice(:name)

          params[:participants] = find_participants(participants)
          params[:starts_at] = parse_datetime(schedule, args[:starts_at]) if args[:starts_at]
          params[:ends_at] = parse_datetime(schedule, args[:ends_at]) if args.key?(:ends_at)

          if args[:rotation_length]
            params.merge!(
              length: args.dig(:rotation_length, :length),
              length_unit: args.dig(:rotation_length, :unit)
            )
          end

          if args.key?(:active_period)
            active_period_start, active_period_end = active_period_times(args)
            params.merge!(
              active_period_start: active_period_start,
              active_period_end: active_period_end
            )
          end

          params
        end

        def parse_datetime(schedule, timestamp)
          timestamp&.asctime&.in_time_zone(schedule.timezone)
        end

        def find_participants(user_array)
          return if user_array.nil?
          return [] if user_array == []

          raise_too_many_users_error if user_array.size > MAXIMUM_PARTICIPANTS

          usernames = user_array.map { |h| h[:username] }
          raise_duplicate_users_error if usernames.size != usernames.uniq.size

          matched_users = UsersFinder.new(current_user, username: usernames).execute.index_by(&:username)
          raise_user_not_found if matched_users.size != user_array.size

          user_array.map { |param| param.to_h.merge(user: matched_users[param[:username]]) }
        end

        def active_period_times(args)
          active_period_args = args.dig(:active_period)

          return [nil, nil] if active_period_args.blank?

          start_time = active_period_args[:start_time]
          end_time = active_period_args[:end_time]

          raise invalid_time_error unless TIME_FORMAT.match?(start_time)
          raise invalid_time_error unless TIME_FORMAT.match?(end_time)

          [start_time, end_time]
        end

        def raise_project_not_found
          raise Gitlab::Graphql::Errors::ArgumentError, 'The project could not be found'
        end

        def raise_schedule_not_found
          raise Gitlab::Graphql::Errors::ArgumentError, 'The schedule could not be found'
        end

        def raise_too_many_users_error
          raise Gitlab::Graphql::Errors::ArgumentError, "A maximum of #{MAXIMUM_PARTICIPANTS} participants can be added"
        end

        def raise_duplicate_users_error
          raise Gitlab::Graphql::Errors::ArgumentError, "A duplicate username is included in the participant list"
        end

        def raise_user_not_found
          raise Gitlab::Graphql::Errors::ArgumentError, "A provided username couldn't be matched to a user"
        end

        def invalid_time_error
          ::Gitlab::Graphql::Errors::ArgumentError.new 'Time given is invalid'
        end
      end
    end
  end
end
