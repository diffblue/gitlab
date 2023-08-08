import { stringify } from 'yaml';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  fetchYamlConfig,
  extractGraphqlDoraData,
  extractGraphqlFlowData,
  extractGraphqlVulnerabilitiesData,
  extractGraphqlMergeRequestsData,
  extractDoraPerformanceScoreCounts,
} from 'ee/analytics/dashboards/api';
import {
  mockDoraMetricsResponseData,
  mockLastVulnerabilityCountData,
  mockFlowMetricsResponseData,
  mockMergeRequestsResponseData,
  mockDoraPerformersScoreResponseData,
  mockDoraPerformersScoreChartData,
} from './mock_data';

describe('Analytics Dashboards api', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchYamlConfig', () => {
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

  describe('extractGraphqlVulnerabilitiesData', () => {
    const vulnerabilityResponse = {
      vulnerability_critical: { identifier: 'vulnerability_critical', value: 7 },
      vulnerability_high: { identifier: 'vulnerability_high', value: 6 },
    };

    const missingVulnerabilityResponse = {
      vulnerability_critical: { identifier: 'vulnerability_critical', value: '-' },
      vulnerability_high: { identifier: 'vulnerability_high', value: '-' },
    };

    it('returns each vulnerability metric', () => {
      const keys = Object.keys(extractGraphqlVulnerabilitiesData([mockLastVulnerabilityCountData]));
      expect(keys).toEqual(['vulnerability_critical', 'vulnerability_high']);
    });

    it('prepares each vulnerability metric for display', () => {
      expect(extractGraphqlVulnerabilitiesData([mockLastVulnerabilityCountData])).toEqual(
        vulnerabilityResponse,
      );
    });

    it('returns `-` when the vulnerability metric is `0`, null or missing', () => {
      [{}, { ...mockLastVulnerabilityCountData, critical: null, high: 0 }].forEach((badData) => {
        expect(extractGraphqlVulnerabilitiesData([badData])).toEqual(missingVulnerabilityResponse);
      });
    });
  });

  describe('extractGraphqlDoraData', () => {
    const doraResponse = {
      change_failure_rate: { identifier: 'change_failure_rate', value: '5.7' },
      deployment_frequency: { identifier: 'deployment_frequency', value: 23.75 },
      lead_time_for_changes: { identifier: 'lead_time_for_changes', value: '0.3' },
      time_to_restore_service: { identifier: 'time_to_restore_service', value: '0.8' },
    };

    it('returns each flow metric', () => {
      const keys = Object.keys(extractGraphqlDoraData(mockDoraMetricsResponseData.metrics));
      expect(keys).toEqual([
        'deployment_frequency',
        'lead_time_for_changes',
        'time_to_restore_service',
        'change_failure_rate',
      ]);
    });

    it('prepares each dora metric for display', () => {
      expect(extractGraphqlDoraData(mockDoraMetricsResponseData.metrics)).toEqual(doraResponse);
    });

    it('replaces null values with 0.0', () => {
      expect(extractGraphqlDoraData([{ change_failure_rate: null }])).toEqual({
        change_failure_rate: { identifier: 'change_failure_rate', value: '0.0' },
      });
    });

    it('returns an empty object given an empty array', () => {
      expect(extractGraphqlDoraData([])).toEqual({});
    });
  });

  describe('extractGraphqlFlowData', () => {
    const flowMetricsResponse = {
      cycle_time: { identifier: 'cycle_time', value: '-' },
      deploys: { identifier: 'deploys', value: 751 },
      issues: { identifier: 'issues', value: 10 },
      issues_completed: { identifier: 'issues_completed', value: 109 },
      lead_time: { identifier: 'lead_time', value: 10 },
    };

    it('returns each flow metric', () => {
      const keys = Object.keys(extractGraphqlFlowData(mockFlowMetricsResponseData));
      expect(keys).toEqual(['lead_time', 'cycle_time', 'issues', 'issues_completed', 'deploys']);
    });

    it('replaces null values with `-`', () => {
      expect(extractGraphqlFlowData(mockFlowMetricsResponseData)).toEqual(flowMetricsResponse);
    });
  });

  describe('extractGraphqlMergeRequestsData', () => {
    it('returns each merge request metric', () => {
      const keys = Object.keys(extractGraphqlMergeRequestsData(mockMergeRequestsResponseData));
      expect(keys).toEqual(['merge_request_throughput']);
    });

    it('replaces null values with `-`', () => {
      expect(extractGraphqlMergeRequestsData({ merge_request_throughput: null })).toEqual({
        merge_request_throughput: { identifier: 'merge_request_throughput', value: '-' },
      });
    });
  });

  describe('extractDoraPerformanceScoreCounts', () => {
    it('returns each DORA performance score category', () => {
      const categories = extractDoraPerformanceScoreCounts(mockDoraPerformersScoreResponseData).map(
        ({ name }) => name,
      );
      expect(categories).toEqual(['High', 'Medium', 'Low', 'Not included']);
    });

    it('prepares DORA performance score counts for display', () => {
      expect(extractDoraPerformanceScoreCounts(mockDoraPerformersScoreResponseData)).toEqual(
        mockDoraPerformersScoreChartData,
      );
    });
  });
});
