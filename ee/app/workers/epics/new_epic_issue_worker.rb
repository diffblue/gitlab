# frozen_string_literal: true

module Epics
  class NewEpicIssueWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :epics

    def perform(params)
      @params = params

      prepare_params
      return if missing_resources?

      create_notes
      usage_ping_record_epic_issue_added
    end

    private

    attr_reader :params, :user, :epic, :issue, :original_epic

    def prepare_params
      @user = ::User.find_by_id(params['user_id'])
      @epic = ::Epic.find_by_id(params['epic_id'])
      @issue = ::Issue.find_by_id(params['issue_id'])

      if params['original_epic_id']
        @original_epic = ::Epic.find_by_id(params['original_epic_id'])
      end
    end

    def missing_resources?
      return true unless user && epic && issue
      return true if params['original_epic_id'].present? && original_epic.nil?

      false
    end

    def issue_moved?
      original_epic.present?
    end

    def create_notes
      if issue_moved?
        SystemNoteService.epic_issue_moved(original_epic, issue, epic, user)
        SystemNoteService.issue_epic_change(issue, epic, user)
      else
        SystemNoteService.epic_issue(epic, issue, user, :added)
        SystemNoteService.issue_on_epic(issue, epic, user, :added)
      end
    end

    def usage_ping_record_epic_issue_added
      ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_issue_added(author: user)
    end
  end
end
