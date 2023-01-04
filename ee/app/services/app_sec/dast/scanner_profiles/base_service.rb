# frozen_string_literal: true

module AppSec
  module Dast
    module ScannerProfiles
      class BaseService < BaseProjectService
        private

        def valid_tags?
          return true unless tag_list?

          tag_list.size == params[:tag_list].size
        end

        def tag_list?
          Feature.enabled?(:on_demand_scans_runner_tags, project) && params[:tag_list].present?
        end

        def tag_list
          @tag_list ||= ActsAsTaggableOn::Tag.named_any(params[:tag_list])
        end

        def tags
          if tag_list?
            tag_list
          else
            []
          end
        end

        def base_params
          {
            target_timeout: params[:target_timeout],
            spider_timeout: params[:spider_timeout],
            scan_type: params[:scan_type],
            use_ajax_spider: params[:use_ajax_spider],
            show_debug_messages: params[:show_debug_messages]
          }
        end
      end
    end
  end
end
