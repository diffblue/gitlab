# frozen_string_literal: true
# rubocop:disable Scalability/IdempotentWorker
# Worker triggers email so cannot be considered idempotent.

module Groups
  class ExportMembershipsWorker
    include ApplicationWorker

    sidekiq_options retry: true
    feature_category :compliance_management
    data_consistency :sticky

    def perform(group_id, current_user_id)
      @group = Group.find_by_id(group_id)
      @current_user = User.find_by_id(current_user_id)
      @response = Groups::Memberships::ExportService.new(container: @group, current_user: @current_user).execute

      send_email if @response.success?
    rescue Module::DelegationError => exception
      # TEMPORARY: Rescue when a User record is not available,
      # see https://gitlab.com/gitlab-org/gitlab/-/issues/338707
      Raven.capture_exception(exception, tags: { group_id: @group.id, user_id: @current_user.id })
    end

    private

    def send_email
      Notify.memberships_export_email(csv_data: @response.payload,
                                      requested_by: @current_user,
                                      group: @group).deliver_later
    end
  end
end
