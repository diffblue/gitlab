# frozen_string_literal: true

module AppSec
  module Dast
    module ScannerProfiles
      class BaseService < BaseProjectService
        private

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
