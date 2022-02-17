# frozen_string_literal: true

class AdjournedProjectsDeletionCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue

  INTERVAL = 10.seconds.to_i

  feature_category :compliance_management

  def perform
    deletion_cutoff = Gitlab::CurrentSettings.deletion_adjourned_period.days.ago.to_date

    Project.with_route.with_deleting_user.aimed_for_deletion(deletion_cutoff).find_each(batch_size: 100).with_index do |project, index| # rubocop: disable CodeReuse/ActiveRecord
      delay = index * INTERVAL

      with_context(project: project, user: project.deleting_user) do
        AdjournedProjectDeletionWorker.perform_in(delay, project.id)
      end
    end
  end
end
