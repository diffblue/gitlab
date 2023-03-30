# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::Watchers, feature_category: :devops_reports do
  context 'for issue' do
    let(:issue) { Issue.new }
    let(:event) { :event }

    describe '.mount' do
      it 'mounts IssueWatcher' do
        expect(Dora::Watchers::IssueWatcher).to receive(:mount)

        described_class.mount(Issue)
      end
    end

    describe '.process_event' do
      it 'delegates to IssueWatcher' do
        expect_next_instance_of(Dora::Watchers::IssueWatcher, issue, event) do |watcher|
          expect(watcher).to receive(:process)
        end

        described_class.process_event(issue, event)
      end
    end
  end
end
