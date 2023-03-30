# frozen_string_literal: true

module Dora
  module Watchers
    class << self
      def mount(subject_class)
        self.for(subject_class).mount(subject_class)
      end

      def process_event(subject, event)
        self.for(subject.class).new(subject, event).process
      end

      private

      def for(subject_class)
        if subject_class <= Issue
          IssueWatcher
        elsif subject_class <= Deployment
          DeploymentWatcher
        end
      end
    end
  end
end
