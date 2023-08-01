# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        class MergeRequestAnalytics < QA::Page::Base
          view "ee/app/assets/javascripts/analytics/merge_request_analytics/components/throughput_stats.vue" do
            element 'throughput-stats'
          end

          view "ee/app/assets/javascripts/analytics/merge_request_analytics/components/throughput_chart.vue" do
            element 'throughput-chart'
          end

          view "ee/app/assets/javascripts/analytics/merge_request_analytics/components/throughput_table.vue" do
            element 'mr-table'
          end

          # Throughput chart
          #
          # @param [Integer] wait
          # @return [Capybara::Node::Element]
          def throughput_chart(wait: 5)
            find_element('throughput-chart', wait: wait)
          end

          # Mean time to merge stat
          #
          # @return [String]
          def mean_time_to_merge
            within_element('throughput-chart') do
              within_element('throughput-stats') do
                value = find_element("displayValue").text
                unit = find_element("unit").text

                "#{value} #{unit}"
              end
            end
          end

          # List of merged mrs
          #
          # @return [Array<Hash>]
          def merged_mrs(expected_count:)
            within_element('mr-table') do
              all_elements("detailsCol", count: expected_count).map do |el|
                {
                  title: el.find("a").text,
                  label_count: el.find("[data-testid=labelDetails]").text.to_i,
                  comment_count: el.find("[data-testid=commentCount]").text.to_i
                }
              end
            end
          end
        end
      end
    end
  end
end
