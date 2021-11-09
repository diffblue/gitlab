# frozen_string_literal: true

module AppSec
  module Fuzzing
    module Coverage
      class CorpusPolicy < BasePolicy
        delegate { @subject.project }
      end
    end
  end
end
