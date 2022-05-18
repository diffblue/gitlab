# frozen_string_literal: true

module EE
  module Groups
    module Analytics
      module ContributionAnalyticsHelper
        def date_range_nav
          [
            {
              label: s_('ContributionAnalytics|Last week'),
              date: 1.week.ago.to_date
            },
            {
              label: s_('ContributionAnalytics|Last month'),
              date: 1.month.ago.to_date
            },
            {
              label: s_('ContributionAnalytics|Last 3 months'),
              date: 3.months.ago.to_date
            }
          ]
        end
      end
    end
  end
end
