# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../states/project/merge_request/show_state'
require_relative '../../../../../../../../spec/contracts/provider/spec_helper'
require_relative '../../../../../../../../spec/contracts/provider/environments/test'

module Provider
  module SuggestedReviewersHelper
    Pact.service_provider "Merge Request Suggested Reviewers Endpoint" do
      app { Environments::Test.app }

      honours_pact_with 'MergeRequest#show' do
        pact_uri '../contracts/project/merge_request/show/mergerequest#show-merge_request_suggested_reviewers_endpoint.json' # rubocop:disable Layout/LineLength
      end
    end
  end
end
