# frozen_string_literal: true

module AlertManagement
  class MetricImage < ApplicationRecord
    self.table_name = 'alert_management_alert_metric_images'

    belongs_to :alert, class_name: 'AlertManagement::Alert', foreign_key: 'alert_id', inverse_of: :metric_images

    validates :file, presence: true
    validates :url, length: { maximum: 255 }, public_url: { allow_blank: true }
    validates :url_text, length: { maximum: 128 }
  end
end
