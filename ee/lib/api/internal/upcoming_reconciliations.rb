# frozen_string_literal: true

module API
  module Internal
    class UpcomingReconciliations < ::API::Base
      before do
        forbidden!('This API is gitlab.com only!') unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
        authenticated_as_admin!
      end

      feature_category :purchase
      urgency :low

      namespace :internal do
        resource :upcoming_reconciliations do
          desc 'Update upcoming reconciliations'
          params do
            requires :upcoming_reconciliations, type: Array[JSON], desc: 'An array of upcoming reconciliations' do
              requires :namespace_id, type: Integer, allow_blank: false
              requires :next_reconciliation_date, type: Date
              requires :display_alert_from, type: Date
            end
          end
          put '/' do
            service = ::UpcomingReconciliations::UpdateService.new(params['upcoming_reconciliations'])
            response = service.execute

            if response.success?
              status 200
            else
              render_api_error!({ error: response.errors.first }, 400)
            end
          end

          desc 'Destroy upcoming reconciliation record'
          params do
            requires :namespace_id, type: Integer, allow_blank: false
          end

          delete '/' do
            upcoming_reconciliation = GitlabSubscriptions::UpcomingReconciliation.next(params[:namespace_id])

            not_found! if upcoming_reconciliation.blank?

            upcoming_reconciliation.destroy!

            no_content!
          end
        end
      end
    end
  end
end
