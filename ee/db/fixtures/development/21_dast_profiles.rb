# frozen_string_literal: true

class Gitlab::Seeder::DastProfiles
  attr_reader :project

  def initialize(project)
    @project = project
    FactoryBot.definition_file_paths << Rails.root.join('ee', 'spec', 'factories')
    FactoryBot.reload # rubocop:disable Cop/ActiveRecordAssociationReload
  end

  def seed!
    3.times { create_profile }

    2.times do
      token = create_token(create_profile)

      create_validation(token)
    end
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
  Project.all.each do |project|
    next unless project.repo_exists?

    seeder = Gitlab::Seeder::DastProfiles.new(project)
    seeder.seed!
  end
end
