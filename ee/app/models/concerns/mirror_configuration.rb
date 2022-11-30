# frozen_string_literal: true

module MirrorConfiguration
  MIRROR_BRANCHES_SETTING = {
    all: 'all',
    protected: 'protected',
    regex: 'regex'
  }.freeze

  def mirror_branches_setting
    return MIRROR_BRANCHES_SETTING[:protected] if only_mirror_protected_branches_column
    return MIRROR_BRANCHES_SETTING[:regex] if mirror_branch_regex.present?

    MIRROR_BRANCHES_SETTING[:all]
  end

  def only_mirror_protected_branches_column
    raise NotImplementedError
  end
end
