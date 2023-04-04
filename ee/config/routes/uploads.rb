# frozen_string_literal: true

scope path: :uploads do
  # Issuable Metric Images
  get "-/system/:model/:mounted_as/:id/:filename",
    to: "uploads#show",
    constraints: { model: /issuable_metric_image/, mounted_as: /file/, filename: %r{[^/]+} },
    as: 'issuable_metric_image_upload'
end
