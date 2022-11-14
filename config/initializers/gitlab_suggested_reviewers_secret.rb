# frozen_string_literal: true

return unless Gitlab.com? && Rails.env.production?

Gitlab::AppliedMl::SuggestedReviewers.ensure_secret!
