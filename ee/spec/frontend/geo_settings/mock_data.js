export const MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE = {
  geo_status_timeout: 10,
  geo_node_allowed_ips: '0.0.0.0/0, ::/0',
};

export const MOCK_BASIC_SETTINGS_DATA = {
  timeout: MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE.geo_status_timeout,
  allowedIp: MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE.geo_node_allowed_ips,
};

export const STRING_OVER_255 = new Array(257).join('a');

export const MOCK_NODES_PATH = 'gitlab/admin/geo/sites';
