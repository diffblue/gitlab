# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Rake::Task['gitlab:seed:vulnerabilities'].invoke
end
