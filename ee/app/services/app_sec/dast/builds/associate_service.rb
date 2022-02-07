# frozen_string_literal: true

module AppSec
  module Dast
    module Builds
      class AssociateService
        def initialize(params)
          @params = params
        end

        def execute
          responses = [associate_site_profile, associate_scanner_profile]

          responses.each { |response| return response if response.error? }

          ServiceResponse.success
        end

        private

        attr_reader :params

        def associate_site_profile
          return ServiceResponse.success unless params[:dast_site_profile_id]

          association = ::Dast::SiteProfilesBuild.new(
            ci_build_id: params[:ci_build_id],
            dast_site_profile_id: params[:dast_site_profile_id]
          )

          save(association).tap do |response|
            if response.error?
              SiteProfilesBuilds::ConsistencyWorker.perform_async(params[:ci_build_id], params[:dast_site_profile_id])
            end
          end
        end

        def associate_scanner_profile
          return ServiceResponse.success unless params[:dast_scanner_profile_id]

          association = ::Dast::ScannerProfilesBuild.new(
            ci_build_id: params[:ci_build_id],
            dast_scanner_profile_id: params[:dast_scanner_profile_id]
          )

          save(association).tap do |response|
            if response.error?
              ScannerProfilesBuilds::ConsistencyWorker.perform_async(params[:ci_build_id], params[:dast_scanner_profile_id])
            end
          end
        end

        def save(association)
          return ServiceResponse.success if association.save

          ServiceResponse.error(message: association.errors.full_messages)
        end
      end
    end
  end
end
