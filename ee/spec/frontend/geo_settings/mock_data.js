export const MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE = {
  geo_status_timeout: 10,
  // `geo_node_allowed_ips` to be renamed `geo_site_allowed_ips` => https://gitlab.com/gitlab-org/gitlab/-/issues/396748
  geo_node_allowed_ips: '0.0.0.0/0, ::/0',
};

export const MOCK_BASIC_SETTINGS_DATA = {
  timeout: MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE.geo_status_timeout,
  // `geo_node_allowed_ips` to be renamed `geo_site_allowed_ips` => https://gitlab.com/gitlab-org/gitlab/-/issues/396748
  allowedIp: MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE.geo_node_allowed_ips,
};

export const STRING_OVER_255 = new Array(257).join('a');

export const MOCK_SITES_PATH = 'gitlab/admin/geo/sites';
