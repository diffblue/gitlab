# frozen_string_literal: true

module Dependencies
  class DependencyListExportPolicy < BasePolicy
    delegate { @subject.exportable }

    condition(:is_author) { @user && @subject.author == @user }
    condition(:exportable) { can?(:read_dependency, @subject.exportable) }

    rule { exportable & is_author }.policy do
      enable :read_dependency_list_export
    end
  end
end
