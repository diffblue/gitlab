# frozen_string_literal: true

class Gitlab::Seeder::MergeRequestPredictions
  TOP_N_SUGGESTED_USERS = 5
  VERSION = "0.0.0"

  def seed!
    MergeRequest.where.not(id: MergeRequest::Predictions.select(:merge_request_id)).find_each do |mr|
      next if mr.predictions.present?

      suggestion = {
        "top_n": TOP_N_SUGGESTED_USERS,
        "version": VERSION,
        "reviewers": mr.project.team.users.sample(TOP_N_SUGGESTED_USERS).map(&:username)
      }

      mr.build_predictions
      mr.predictions.update!(suggested_reviewers: suggestion)

      print '.'
    end
  end
end

Gitlab::Seeder.quiet do
  Gitlab::Seeder::MergeRequestPredictions.new.seed!
end
