# frozen_string_literal: true

RSpec.shared_examples 'query dastProfiles.dastProfileSchedule shared examples' do |create_new_project: false|
  it 'avoids N+1 queries' do
    profile_project = if create_new_project
                        create(:project, :repository, group: group)
                      else
                        project
                      end

    profile_project.add_developer(current_user)
    extra_users = create_list(:user, 6)
    extra_users.each do |user|
      profile_project.add_developer(user)
    end

    control = ActiveRecord::QueryRecorder.new(query_recorder_debug: true) do
      run_query(query)
    end

    extra_users.each do |extra_user|
      create(
        :dast_profile_schedule,
        project: profile_project,
        dast_profile: create(:dast_profile, project: profile_project), owner: extra_user
      )
    end

    expect { run_query(query) }.not_to exceed_query_limit(control)
  end
end
