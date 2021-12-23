# frozen_string_literal: true

module Projects::Security::DiscoverHelper
  def pql_three_cta_test_experiment_candidate?(namespace)
    experiment(:pql_three_cta_test, namespace: namespace) do |e|
      e.use { false }
      e.try { true }
    end.run
  end
end
