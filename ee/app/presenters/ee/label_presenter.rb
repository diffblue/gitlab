# frozen_string_literal: true

module EE
  module LabelPresenter
    extend ::Gitlab::Utils::DelegatorOverride

    delegator_override :scoped_label?
    def scoped_label?
      label.scoped_label? && context_subject && context_subject.feature_available?(:scoped_labels)
    end
  end
end
