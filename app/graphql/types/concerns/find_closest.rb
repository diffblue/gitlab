# frozen_string_literal: true

module FindClosest
  def closest_parent(types, parent)
    while parent

      if types.any? {|type| parent.instance_of? type}
        return parent
      else
        parent = parent.try(:parent)
      end
    end
  end
end
