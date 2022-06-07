# frozen_string_literal: true

class Geo::DeletedProject
  include ActiveModel::Validations

  attr_accessor :id, :name, :disk_path

  validates :id, :name, :disk_path, presence: true

  def initialize(id:, name:, disk_path:, repository_storage:)
    @id = id
    @name = name
    @disk_path = disk_path
    @repository_storage = repository_storage
  end

  alias_method :full_path, :disk_path

  def repository
    @repository ||= Repository.new(disk_path, self, shard: repository_storage)
  end

  def repository_storage
    @repository_storage ||= Gitlab::CurrentSettings.pick_repository_storage
  end

  def wiki
    @wiki ||= ProjectWiki.new(self, nil)
  end

  def wiki_path
    wiki.disk_path
  end
end
