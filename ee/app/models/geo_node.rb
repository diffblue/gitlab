# frozen_string_literal: true

class GeoNode < ApplicationRecord
  include Presentable
  include Geo::SelectiveSync
  include StripAttribute

  SELECTIVE_SYNC_TYPES = %w[namespaces shards].freeze

  # Array of repository storages to synchronize for selective sync by shards
  serialize :selective_sync_shards, Array # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :oauth_application, class_name: 'Doorkeeper::Application', dependent: :destroy, autosave: true # rubocop: disable Cop/ActiveRecordDependent

  has_many :geo_node_namespace_links
  has_many :namespaces, through: :geo_node_namespace_links
  has_one :status, class_name: 'GeoNodeStatus'

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
  validates :url, presence: true, addressable_url: true
  validates :internal_url, addressable_url: true, allow_blank: true, allow_nil: true

  validates :primary, uniqueness: { message: 'node already exists' }, if: :primary
  validates :enabled, if: :primary, acceptance: { message: 'Geo primary node cannot be disabled' }

  validates :access_key, presence: true
  validates :encrypted_secret_access_key, presence: true

  validates :selective_sync_type, inclusion: {
    in: SELECTIVE_SYNC_TYPES,
    allow_blank: true,
    allow_nil: true
  }

  validates :repos_max_capacity, numericality: { greater_than_or_equal_to: 0 }
  validates :files_max_capacity, numericality: { greater_than_or_equal_to: 0 }
  validates :verification_max_capacity, numericality: { greater_than_or_equal_to: 0 }
  validates :container_repositories_max_capacity, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_reverification_interval, numericality: { greater_than_or_equal_to: 1 }

  validate :require_current_node_to_be_primary, if: :secondary?
  validate :require_hashed_storage, on: :create

  after_save :expire_cache!
  after_destroy :expire_cache!

  before_validation :update_dependents_attributes
  before_validation :ensure_access_keys!

  alias_method :repair, :save # the `update_dependents_attributes` hook will take care of it

  scope :with_url_prefix, ->(prefix) { where('url LIKE ?', "#{prefix}%") }
  scope :secondary_nodes, -> { where(primary: false) }
  scope :name_in, -> (names) { where(name: names) }
  scope :ordered, -> { order(:id) }

  attr_encrypted :secret_access_key,
                 key: Settings.attr_encrypted_db_key_base_32,
                 algorithm: 'aes-256-gcm',
                 mode: :per_attribute_iv,
                 encode: true

  strip_attributes :name

  class << self
    # Set in gitlab.rb as external_url
    def current_node_url
      Gitlab::SafeRequestStore.fetch('geo_node:current_node_url') do
        Gitlab.config.gitlab.url
      end
    end

    # Set in gitlab.rb as geo_node_name
    def current_node_name
      Gitlab::SafeRequestStore.fetch('geo_node:current_node_name') do
        Gitlab.config.geo.node_name
      end
    end

    def current_node
      return unless column_names.include?('name')

      GeoNode.find_by(name: current_node_name)
    end

    def primary_node
      find_by(primary: true)
    end

    def unhealthy_nodes
      status_table = GeoNodeStatus.arel_table

      query = status_table[:id].eq(nil)
        .or(status_table[:cursor_last_event_id].eq(nil))
        .or(status_table[:last_successful_status_check_at].eq(nil))
        .or(status_table[:last_successful_status_check_at].lt(10.minutes.ago))

      left_join_status.where(query)
    end

    def min_cursor_last_event_id
      left_join_status.minimum(:cursor_last_event_id)
    end

    def current?(node)
      node.present? && current_node_name == node.name
    end

    # Tries to find a GeoNode by oauth_application_id, returning nil if none could be found.
    def find_by_oauth_application_id(oauth_application_id)
      find_by(oauth_application_id: oauth_application_id)
    end

    private

    def left_join_status
      join_statement = arel_table.join(GeoNodeStatus.arel_table, Arel::Nodes::OuterJoin)
        .on(arel_table[:id].eq(GeoNodeStatus.arel_table[:geo_node_id]))

      joins(join_statement.join_sources)
    end
  end

  def secondary?
    !primary
  end

  def uses_ssh_key?
    secondary? && clone_protocol == 'ssh'
  end

  def name
    value = read_attribute(:name)

    if looks_like_url_field_missing_slash?(value)
      add_ending_slash(value)
    else
      value
    end
  end

  def name=(value)
    if looks_like_url_field_missing_slash?(value)
      write_with_ending_slash(:name, value)
    else
      write_attribute(:name, value)
    end
  end

  def url
    read_with_ending_slash(:url)
  end

  def url=(value)
    write_with_ending_slash(:url, value)

    @uri = nil
  end

  def internal_url
    read_with_ending_slash(:internal_url).presence || read_with_ending_slash(:url)
  end

  def internal_url=(value)
    value = add_ending_slash(value) != url ? value : nil
    write_with_ending_slash(:internal_url, value)
    @internal_uri = nil
  end

  def uri
    @uri ||= URI.parse(url) if url.present?
  end

  def internal_uri
    @internal_uri ||= URI.parse(internal_url) if internal_url.present?
  end

  # Geo API endpoint for retrieving a replicable item
  #
  # @param [String] replicable_name
  # @param [Integer] replicable_id
  def geo_retrieve_url(replicable_name:, replicable_id:)
    geo_api_url("retrieve/#{replicable_name}/#{replicable_id}")
  end

  # Geo API endpoint for retrieving a file based on Uploads
  #
  # @deprecated
  # @param [String] file_type
  # @param [Integer] file_id
  def geo_transfers_url(file_type, file_id)
    geo_api_url("transfers/#{file_type}/#{file_id}")
  end

  def status_url
    geo_api_url('status')
  end

  def node_api_url(node)
    api_url("geo_nodes/#{node.id}")
  end

  def snapshot_url(repository)
    url = api_url("projects/#{repository.project.id}/snapshot")
    url += "?wiki=1" if repository.repo_type.wiki?

    url
  end

  def repository_url(repository)
    Gitlab::Utils.append_path(internal_url, "#{repository.full_path}.git")
  end

  def oauth_callback_url
    Gitlab::Routing.url_helpers.oauth_geo_callback_url(url_helper_args)
  end

  def oauth_logout_url(state)
    Gitlab::Routing.url_helpers.oauth_geo_logout_url(url_helper_args.merge(state: state))
  end

  def geo_projects_url
    return unless self.secondary?

    Gitlab::Routing.url_helpers.admin_geo_projects_url(url_helper_args)
  end

  def missing_oauth_application?
    self.primary? ? false : !oauth_application.present?
  end

  def update_clone_url!
    update_clone_url

    # Update with update_column to prevent calling callbacks as this method will
    # be called in an initializer and we don't want other callbacks
    # to mess with uninitialized dependencies.
    if clone_url_prefix_changed?
      Gitlab::AppLogger.info "Geo: modified clone_url_prefix to #{clone_url_prefix}"
      update_column(:clone_url_prefix, clone_url_prefix)
    end
  end

  def container_repositories
    return ContainerRepository.none unless Geo::ContainerRepositoryRegistry.replication_enabled?
    return ContainerRepository.all unless selective_sync?

    ContainerRepository.project_id_in(projects)
  end

  def container_repositories_include?(container_repository_id)
    return false unless Geo::ContainerRepositoryRegistry.replication_enabled?
    return true unless selective_sync?

    container_repositories.where(id: container_repository_id).exists?
  end

  def designs
    projects.with_designs
  end

  def designs_include?(project_id)
    return true unless selective_sync?

    designs.where(id: project_id).exists?
  end

  # @param primary_key_in [Range, LfsObject] arg to pass to primary_key_in scope
  # @return [ActiveRecord::Relation<LfsObject>] scope of LfsObject filtered by selective sync settings and primary key arg
  def lfs_objects(primary_key_in:)
    return LfsObject.primary_key_in(primary_key_in) unless selective_sync?

    ids = LfsObjectsProject.project_id_in(projects)
                           .where(lfs_object_id: primary_key_in)
                           .select(:lfs_object_id)
                           .distinct

    LfsObject.where(id: ids)
  end

  def projects
    return Project.all unless selective_sync?

    if selective_sync_by_namespaces?
      projects_for_selected_namespaces
    elsif selective_sync_by_shards?
      projects_for_selected_shards
    else
      Project.none
    end
  end

  def projects_include?(project_id)
    return true unless selective_sync?

    projects.where(id: project_id).exists?
  end

  def replication_slots_count
    return unless primary?

    Postgresql::ReplicationSlot.count
  end

  def replication_slots_used_count
    return unless primary?

    Postgresql::ReplicationSlot.used_slots_count
  end

  def replication_slots_max_retained_wal_bytes
    return unless primary?

    Postgresql::ReplicationSlot.max_retained_wal
  end

  def find_or_build_status
    status || build_status
  end

  private

  def geo_api_url(suffix)
    api_url("geo/#{suffix}")
  end

  def api_url(suffix)
    Gitlab::Utils.append_path(internal_uri.to_s, "api/#{API::API.version}/#{suffix}")
  end

  def ensure_access_keys!
    return if self.access_key.present? && self.encrypted_secret_access_key.present?

    keys = Gitlab::Geo.generate_access_keys

    self.access_key = keys[:access_key]
    self.secret_access_key = keys[:secret_access_key]
  end

  def url_helper_args
    url_helper_options(uri)
  end

  def url_helper_options(given_uri)
    { protocol: given_uri.scheme, host: given_uri.host, port: given_uri.port, script_name: given_uri.path }
  end

  def update_dependents_attributes
    if self.primary?
      self.oauth_application&.destroy
      self.oauth_application = nil

      update_clone_url
    else
      update_oauth_application!
    end
  end

  # Prevent locking yourself out
  def require_current_node_to_be_primary
    if name == self.class.current_node_name
      errors.add(:base, _('Current node must be the primary node or you will be locking yourself out'))
    end
  end

  # Prevent creating a Geo Node unless Hashed Storage is enabled
  def require_hashed_storage
    unless Gitlab::CurrentSettings.hashed_storage_enabled?
      errors.add(:base, _('Hashed Storage must be enabled to use Geo'))
    end
  end

  def update_clone_url
    self.clone_url_prefix = Gitlab.config.gitlab_shell.ssh_path_prefix
  end

  def update_oauth_application!
    return unless uri

    if oauth_application.nil?
      self.build_oauth_application
      self.oauth_application.trusted = true
      self.oauth_application.confidential = true
    end

    self.oauth_application.name = "Geo node: #{self.url}"
    self.oauth_application.redirect_uri = oauth_callback_url
  end

  def expire_cache!
    Gitlab::Geo.expire_cache!
  end

  # This method is required for backward compatibility. If it
  # returns true,  then we can be fairly confident they did not
  # set gitlab_rails['geo_node_name']. But if it returns false,
  # then we aren't sure, so we shouldn't touch the name value.
  def looks_like_url_field_missing_slash?(value)
    add_ending_slash(value) == url
  end

  def read_with_ending_slash(attribute)
    value = read_attribute(attribute)

    add_ending_slash(value)
  end

  def write_with_ending_slash(attribute, value)
    value = add_ending_slash(value)

    write_attribute(attribute, value)
  end

  def add_ending_slash(value)
    return value if value.blank?
    return value if value.end_with?('/')

    "#{value}/"
  end

  def projects_for_selected_namespaces
    Project.where(Project.arel_table.name => { namespace_id: selected_namespaces_and_descendants.select(:id) })
  end

  def projects_for_selected_shards
    Project.within_shards(selective_sync_shards)
  end
end
