import { stringify } from 'yaml';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { fetchYamlConfig } from 'ee/analytics/dashboards/yaml_utils';

describe('fetchYamlConfig', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  const YAML_PROJECT_ID = 1337;
  const API_PATH = /\/api\/(.*)\/projects\/(.*)\/repository\/files\/\.gitlab%2Fanalytics%2Fdashboards%2Fvalue_streams%2Fvalue_streams\.ya?ml\/raw/;

  it('returns null if the project ID is falsey', async () => {
    const config = await fetchYamlConfig(null);
    expect(config).toBeNull();
  });

  it('returns null if the file fails to load', async () => {
    mock.onGet(API_PATH).reply(HTTP_STATUS_NOT_FOUND);
    const config = await fetchYamlConfig(YAML_PROJECT_ID);
    expect(config).toBeNull();
  });

  it('returns null if the YAML config fails to parse', async () => {
    mock.onGet(API_PATH).reply(HTTP_STATUS_OK, { data: null });
    const config = await fetchYamlConfig(YAML_PROJECT_ID);
    expect(config).toBeNull();
  });

  it('returns the parsed YAML config on success', async () => {
    const mockConfig = {
      title: 'TITLE',
      description: 'DESC',
      widgets: [{ data: { namespace: 'test/one' } }, { data: { namespace: 'test/two' } }],
    };

    mock.onGet(API_PATH).reply(HTTP_STATUS_OK, stringify(mockConfig));
    const config = await fetchYamlConfig(YAML_PROJECT_ID);
    expect(config).toEqual(mockConfig);
  });
});
