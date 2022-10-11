# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Group.not_mass_generated.each do |group|
    5.times do
      states = %w[opened closed]
      days_ago = rand(21)

      params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        created_at: rand(21).days.ago,
        state: states.sample,
        labels: group.labels.sample(rand(6)).pluck(:title).join(',')
      }
      params[:closed_at] = rand(days_ago).days.ago if params[:state] == 'closed'

      epic = ::Epics::CreateService.new(group: group, current_user: group.users.sample, params: params)
               .execute_without_rate_limiting

      print '.' if epic.persisted?
    end
  end
end
