# frozen_string_literal: true

module Gitlab
  module AppliedMl
    module SuggestedReviewers
      module RecommenderServicesPb
        class Service
          include ::GRPC::GenericService
          include Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb

          self.marshal_class_method = :encode
          self.unmarshal_class_method = :decode
          self.service_name = 'bot.RecommenderService'

          rpc :MergeRequestRecommendationsV2, MergeRequestRecommendationsReqV2, MergeRequestRecommendationsResV2
          rpc :RegisterProject, RegisterProjectReq, RegisterProjectRes
          rpc :DeregisterProject, DeregisterProjectReq, DeregisterProjectRes
        end

        Stub = Service.rpc_stub_class
      end
    end
  end
end
