# frozen_string_literal: true

class Gitlab::Seeder::DastProfiles
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def seed!
    profile = create_profile

    token = create_token(profile)

    create_validation(token)
  end

  private

  def create_profile
    site_profile = create_site_profile(create_site)

    FactoryBot.create(:dast_profile, project: project, dast_site_profile: site_profile)
  end

  def create_site
    FactoryBot.create(:dast_site, project: project, url: "https://#{SecureRandom.hex}.com")
  end

  def create_site_profile(site)
    FactoryBot.create(:dast_site_profile, project: project, dast_site: site)
  end

  def create_token(profile)
    url = profile.dast_site_profile.dast_site.url

    FactoryBot.create(:dast_site_token, project: project, url: url)
  end

  def create_validation(token)
    FactoryBot.create(:dast_site_validation, dast_site_token: token)
  end
end

Gitlab::Seeder.quiet do
  user = User.first

  user.projects.order(id: :desc).limit(3).each do |project|
    next unless project.repo_exists?

    seeder = Gitlab::Seeder::DastProfiles.new(project)
    seeder.seed!
  end
end
