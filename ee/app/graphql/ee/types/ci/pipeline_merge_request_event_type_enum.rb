# frozen_string_literal: true

module EE
  module Types
    module Ci
      module PipelineMergeRequestEventTypeEnum
        extend ActiveSupport::Concern

        prepended do
          value 'MERGE_TRAIN', 'Pipeline ran as part of a merge train.', value: :merge_train
        end
      end
    end
  end
end
