# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        class Subscription < QA::Page::Base
          view 'ee/app/assets/javascripts/admin/subscriptions/show/components/subscription_breakdown.vue' do
            element 'remove-license'
          end

          view 'ee/app/assets/javascripts/admin/subscriptions/show/components/subscription_details_table.vue' do
            element 'plan', 'itemDetailTestId' # rubocop:disable QA/ElementWithPattern
          end

          def license?
            has_element?('remove-license')
          end

          def has_ultimate_subscription_plan?
            has_element?('plan', text: 'Ultimate')
          end
        end
      end
    end
  end
end
