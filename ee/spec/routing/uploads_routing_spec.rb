# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Uploads', 'routing' do
  it 'allows fetching issuable metric images' do
    expect(get('/uploads/-/system/issuable_metric_image/file/1/test.jpg')).to route_to(
      controller: 'uploads',
      action: 'show',
      model: 'issuable_metric_image',
      id: '1',
      filename: 'test.jpg',
      mounted_as: 'file'
    )
  end

  it 'allows fetching alert metric metric images' do
    expect(get('/uploads/-/system/alert_management_metric_image/file/1/test.jpg')).to route_to(
      controller: 'uploads',
      action: 'show',
      model: 'alert_management_metric_image',
      id: '1',
      filename: 'test.jpg',
      mounted_as: 'file'
    )
  end
end
