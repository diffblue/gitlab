# frozen_string_literal: true

module Gitlab
  module Audit
    module Events
      class Preloader
        def self.preload!(audit_events)
          audit_events.tap do |audit_events|
            audit_events.each do |audit_event|
              audit_event.lazy_author
              audit_event.entity
            end
          end
        end

        def initialize(audit_events)
          @audit_events = audit_events
        end

        def find_each(&block)
          @audit_events.each_batch(column: :created_at) do |relation|
            relation.each do |audit_event|
              audit_event.lazy_author
              audit_event.entity
            end

            relation.each do |audit_event|
              yield(audit_event)
            end

            BatchLoader::Executor.clear_current
          end
        end
      end
    end
  end
end
