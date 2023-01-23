import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  getTypeOfWorkTasksByType,
  getTypeOfWorkTopLabels,
  getValueStreams,
  getGroupLabels,
  getDurationChart,
  getStageEvents,
  getGroupStagesAndEvents,
  createValueStream,
  updateValueStream,
  deleteValueStream,
} from 'ee/api/analytics_api';
import * as valueStreamAnalyticsConstants from 'ee/analytics/cycle_analytics/constants';
import * as analyticsMockData from 'ee_jest/analytics/cycle_analytics/mock_data';

const dummyApiVersion = 'v3000';
const dummyUrlRoot = '/gitlab';
const dummyGon = {
  api_version: dummyApiVersion,
  relative_url_root: dummyUrlRoot,
};

let originalGon;
let mock;

describe('ValueStreamAnalyticsApi', () => {
  const createdBefore = '2019-11-18';
  const createdAfter = '2019-08-18';
  const groupId = 'counting-54321';
  const stageId = 'thursday';
  const valueStreamId = 'a-city-by-the-light-divided';
  const dummyValueStreamAnalyticsUrlRoot = `${dummyUrlRoot}/groups/${groupId}/-/analytics/value_stream_analytics`;
  const defaultParams = {
    created_after: createdAfter,
    created_before: createdBefore,
  };
  const valueStreamBaseUrl = ({ resource = '', id = null }) =>
    [dummyValueStreamAnalyticsUrlRoot, id ? `value_streams/${id}/${resource}` : resource].join('/');

  const expectRequestWithCorrectParameters = (responseObj, { params, expectedUrl, response }) => {
    const {
      data,
      config: { params: reqParams, url },
    } = responseObj;
    expect(data).toEqual(response);
    expect(reqParams).toEqual(params);
    expect(url).toEqual(expectedUrl);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('getTypeOfWorkTasksByType', () => {
    it('fetches tasks by type data', async () => {
      const tasksByTypeResponse = [
        {
          label: {
            id: 9,
            title: 'Thursday',
            color: '#7F8C8D',
            description: 'What are you waiting for?',
            group_id: 2,
            project_id: null,
            template: false,
            text_color: '#FFFFFF',
            created_at: '2019-08-20T05:22:49.046Z',
            updated_at: '2019-08-20T05:22:49.046Z',
          },
          series: [['2019-11-03', 5]],
        },
      ];
      const labelNames = ['Thursday', 'Friday', 'Saturday'];
      const params = {
        ...defaultParams,
        project_ids: null,
        subject: valueStreamAnalyticsConstants.TASKS_BY_TYPE_SUBJECT_ISSUE,
        label_names: labelNames,
      };
      const expectedUrl = analyticsMockData.endpoints.tasksByTypeData;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, tasksByTypeResponse);

      const {
        data,
        config: { params: reqParams },
      } = await getTypeOfWorkTasksByType(groupId, params);
      expect(data).toEqual(tasksByTypeResponse);
      expect(reqParams).toEqual(params);
    });
  });

  describe('getTypeOfWorkTopLabels', () => {
    it('fetches top group level labels', async () => {
      const response = [];
      const params = {
        ...defaultParams,
        project_ids: null,
        subject: valueStreamAnalyticsConstants.TASKS_BY_TYPE_SUBJECT_ISSUE,
      };

      const expectedUrl = analyticsMockData.endpoints.tasksByTypeTopLabelsData;
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

      const {
        data,
        config: { url, params: reqParams },
      } = await getTypeOfWorkTopLabels(groupId, params);
      expect(data).toEqual(response);
      expect(url).toMatch(expectedUrl);
      expect(reqParams).toEqual(params);
    });
  });

  describe('getValueStreams', () => {
    it('fetches custom value streams', async () => {
      const response = [{ name: 'value stream 1', id: 1 }];
      const expectedUrl = valueStreamBaseUrl({ resource: 'value_streams' });
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

      const responseObj = await getValueStreams(groupId);
      expectRequestWithCorrectParameters(responseObj, {
        response,
        expectedUrl,
      });
    });
  });

  describe('createValueStream', () => {
    it('submit the custom value stream data', async () => {
      const response = {};
      const customValueStream = { name: 'cool-value-stream-stage' };
      const expectedUrl = valueStreamBaseUrl({ resource: 'value_streams' });
      mock.onPost(expectedUrl).reply(HTTP_STATUS_OK, response);

      const {
        data,
        config: { data: reqData, url },
      } = await createValueStream(groupId, customValueStream);
      expect(data).toEqual(response);
      expect(JSON.parse(reqData)).toMatchObject(customValueStream);
      expect(url).toEqual(expectedUrl);
    });
  });

  describe('updateValueStream', () => {
    it('updates the custom value stream data', async () => {
      const response = {};
      const customValueStream = { name: 'cool-value-stream-stage', stages: [] };
      const expectedUrl = valueStreamBaseUrl({ resource: `value_streams/${valueStreamId}` });
      mock.onPut(expectedUrl).reply(HTTP_STATUS_OK, response);

      const {
        data,
        config: { data: reqData, url },
      } = await updateValueStream({
        groupId,
        valueStreamId,
        data: customValueStream,
      });
      expect(data).toEqual(response);
      expect(JSON.parse(reqData)).toMatchObject(customValueStream);
      expect(url).toEqual(expectedUrl);
    });
  });

  describe('deleteValueStream', () => {
    it('delete the custom value stream', async () => {
      const response = {};
      const expectedUrl = valueStreamBaseUrl({ resource: `value_streams/${valueStreamId}` });
      mock.onDelete(expectedUrl).reply(HTTP_STATUS_OK, response);

      const {
        data,
        config: { url },
      } = await deleteValueStream(groupId, valueStreamId);
      expect(data).toEqual(response);
      expect(url).toEqual(expectedUrl);
    });
  });

  describe('getGroupStagesAndEvents', () => {
    it('fetches custom stage events and all stages', async () => {
      const response = { events: [], stages: [] };
      const params = {
        group_id: groupId,
        'cycle_analytics[created_after]': createdAfter,
        'cycle_analytics[created_before]': createdBefore,
      };
      const expectedUrl = valueStreamBaseUrl({ id: valueStreamId, resource: 'stages' });
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

      const responseObj = await getGroupStagesAndEvents({
        groupId,
        valueStreamId,
        params,
      });
      expectRequestWithCorrectParameters(responseObj, {
        response,
        params,
        expectedUrl,
      });
    });
  });

  describe('getStageEvents', () => {
    it('fetches stage events', async () => {
      const response = { events: [] };
      const params = { ...defaultParams };
      const expectedUrl = valueStreamBaseUrl({
        id: valueStreamId,
        resource: `stages/${stageId}/records`,
      });
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

      const responseObj = await getStageEvents({
        groupId,
        valueStreamId,
        stageId,
        params,
      });
      expectRequestWithCorrectParameters(responseObj, {
        response,
        params,
        expectedUrl,
      });
    });
  });

  describe('getDurationChart', () => {
    it('fetches stage duration data', async () => {
      const response = [];
      const params = { ...defaultParams };
      const expectedUrl = valueStreamBaseUrl({
        id: valueStreamId,
        resource: `stages/${stageId}/average_duration_chart`,
      });
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

      const responseObj = await getDurationChart({
        groupId,
        valueStreamId,
        stageId,
        params,
      });
      expectRequestWithCorrectParameters(responseObj, {
        response,
        params,
        expectedUrl,
      });
    });
  });

  describe('getGroupLabels', () => {
    it('fetches group level labels', async () => {
      const response = [];
      const expectedUrl = `${dummyUrlRoot}/groups/${groupId}/-/labels.json`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);

      const {
        data,
        config: { url },
      } = await getGroupLabels(groupId);
      expect(data).toEqual(response);
      expect(url).toEqual(expectedUrl);
    });
  });
});
