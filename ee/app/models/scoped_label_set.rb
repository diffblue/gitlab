# frozen_string_literal: true

class ScopedLabelSet
  attr_reader :labels, :key

  def self.from_label_ids(ids)
    by_key = Hash.new { |hash, key| hash[key] = new(key) }
    labels = Label.select(:id, :title, :lock_on_merge).where(id: ids)

    labels.each do |label|
      key = label.scoped_label_key
      by_key[key].add(label)
    end

    by_key.values
  end

  def initialize(key, labels = [])
    @key = key
    @labels = labels
  end

  def add(label)
    labels << label
  end

  def last_id_by_order(label_ids_order)
    by_index = label_ids_order.map.with_index { |id, idx| [id.to_i, idx] }.to_h

    label_ids.max do |id1, id2|
      by_index.fetch(id1, -1) <=> by_index.fetch(id2, -1)
    end
  end

  def valid?
    key.nil? || labels.count < 2
  end

  def contains_any?(ids)
    (label_ids & ids).present?
  end

  def label_ids
    labels.map(&:id)
  end

  def lock_on_merge_labels?
    labels.any?(&:lock_on_merge)
  end
end
