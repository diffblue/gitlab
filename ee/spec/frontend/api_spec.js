import MockAdapter from 'axios-mock-adapter';
import * as valueStreamAnalyticsConstants from 'ee/analytics/cycle_analytics/constants';
import Api from 'ee/api';
import * as analyticsMockData from 'ee_jest/analytics/cycle_analytics/mock_data';
import axios from '~/lib/utils/axios_utils';
import { ContentTypeMultipartFormData } from '~/lib/utils/headers';
import httpStatus from '~/lib/utils/http_status';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };
  const mockEpics = [
    {
      id: 1,
      iid: 10,
      group_id: 2,
      title: 'foo',
    },
    {
      id: 2,
      iid: 11,
      group_id: 2,
      title: 'bar',
    },
  ];

  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('ldapGroups', () => {
    it('calls callback on completion', (done) => {
      const query = 'query';
      const provider = 'provider';
      const callback = jest.fn();
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/ldap/${provider}/groups.json`;

      mock.onGet(expectedUrl).reply(httpStatus.OK, [
        {
          name: 'test',
        },
      ]);

      Api.ldapGroups(query, provider, callback)
        .then((response) => {
          expect(callback).toHaveBeenCalledWith(response);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('createChildEpic', () => {
    it('calls `axios.post` using params `groupId`, `parentEpicIid` and title', (done) => {
      const groupId = 'gitlab-org';
      const parentEpicId = 1;
      const title = 'Sample epic';
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics`;
      const expectedRes = {
        title,
        id: 20,
        parentId: 5,
      };

      mock.onPost(expectedUrl).reply(httpStatus.OK, expectedRes);

      Api.createChildEpic({ groupId, parentEpicId, title })
        .then(({ data }) => {
          expect(data.title).toBe(expectedRes.title);
          expect(data.id).toBe(expectedRes.id);
          expect(data.parentId).toBe(expectedRes.parentId);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('groupEpics', () => {
    it('calls `axios.get` using param `groupId`', (done) => {
      const groupId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics`;

      mock
        .onGet(expectedUrl, {
          params: {
            include_ancestor_groups: false,
            include_descendant_groups: true,
          },
        })
        .reply(httpStatus.OK, mockEpics);

      Api.groupEpics({ groupId })
        .then(({ data }) => {
          data.forEach((epic, index) => {
            expect(epic.id).toBe(mockEpics[index].id);
            expect(epic.iid).toBe(mockEpics[index].iid);
            expect(epic.group_id).toBe(mockEpics[index].group_id);
            expect(epic.title).toBe(mockEpics[index].title);
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls `axios.get` using param `search` when it is provided', (done) => {
      const groupId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics`;

      mock
        .onGet(expectedUrl, {
          params: {
            include_ancestor_groups: false,
            include_descendant_groups: true,
            search: 'foo',
          },
        })
        .reply(httpStatus.OK, mockEpics);

      Api.groupEpics({ groupId, search: 'foo' })
        .then(({ data }) => {
          data.forEach((epic, index) => {
            expect(epic.id).toBe(mockEpics[index].id);
            expect(epic.iid).toBe(mockEpics[index].iid);
            expect(epic.group_id).toBe(mockEpics[index].group_id);
            expect(epic.title).toBe(mockEpics[index].title);
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('addEpicIssue', () => {
    it('calls `axios.post` using params `groupId`, `epicIid` and `issueId`', (done) => {
      const groupId = 2;
      const mockIssue = {
        id: 20,
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${mockEpics[0].iid}/issues/${mockIssue.id}`;
      const expectedRes = {
        id: 30,
        epic: mockEpics[0],
        issue: mockIssue,
      };

      mock.onPost(expectedUrl).reply(httpStatus.OK, expectedRes);

      Api.addEpicIssue({ groupId, epicIid: mockEpics[0].iid, issueId: mockIssue.id })
        .then(({ data }) => {
          expect(data.id).toBe(expectedRes.id);
          expect(data.epic).toEqual(expect.objectContaining({ ...expectedRes.epic }));
          expect(data.issue).toEqual(expect.objectContaining({ ...expectedRes.issue }));
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('removeEpicIssue', () => {
    it('calls `axios.delete` using params `groupId`, `epicIid` and `epicIssueId`', (done) => {
      const groupId = 2;
      const mockIssue = {
        id: 20,
        epic_issue_id: 40,
      };
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/epics/${mockEpics[0].iid}/issues/${mockIssue.epic_issue_id}`;
      const expectedRes = {
        id: 30,
        epic: mockEpics[0],
        issue: mockIssue,
      };

      mock.onDelete(expectedUrl).reply(httpStatus.OK, expectedRes);

      Api.removeEpicIssue({
        groupId,
        epicIid: mockEpics[0].iid,
        epicIssueId: mockIssue.epic_issue_id,
      })
        .then(({ data }) => {
          expect(data.id).toBe(expectedRes.id);
          expect(data.epic).toEqual(expect.objectContaining({ ...expectedRes.epic }));
          expect(data.issue).toEqual(expect.objectContaining({ ...expectedRes.issue }));
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('Value Stream Analytics', () => {
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
      [dummyValueStreamAnalyticsUrlRoot, id ? `value_streams/${id}/${resource}` : resource].join(
        '/',
      );

    const expectRequestWithCorrectParameters = (responseObj, { params, expectedUrl, response }) => {
      const {
        data,
        config: { params: reqParams, url },
      } = responseObj;
      expect(data).toEqual(response);
      expect(reqParams).toEqual(params);
      expect(url).toEqual(expectedUrl);
    };

    describe('cycleAnalyticsTasksByType', () => {
      it('fetches tasks by type data', (done) => {
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
        const labelIds = [10, 9, 8, 7];
        const params = {
          ...defaultParams,
          project_ids: null,
          subject: valueStreamAnalyticsConstants.TASKS_BY_TYPE_SUBJECT_ISSUE,
          label_ids: labelIds,
        };
        const expectedUrl = analyticsMockData.endpoints.tasksByTypeData;
        mock.onGet(expectedUrl).reply(httpStatus.OK, tasksByTypeResponse);

        Api.cycleAnalyticsTasksByType(groupId, params)
          .then(({ data, config: { params: reqParams } }) => {
            expect(data).toEqual(tasksByTypeResponse);
            expect(reqParams).toEqual(params);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsTopLabels', () => {
      it('fetches top group level labels', (done) => {
        const response = [];
        const labelIds = [10, 9, 8, 7];
        const params = {
          ...defaultParams,
          project_ids: null,
          subject: valueStreamAnalyticsConstants.TASKS_BY_TYPE_SUBJECT_ISSUE,
          label_ids: labelIds,
        };

        const expectedUrl = analyticsMockData.endpoints.tasksByTypeTopLabelsData;
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsTopLabels(groupId, params)
          .then(({ data, config: { url, params: reqParams } }) => {
            expect(data).toEqual(response);
            expect(url).toMatch(expectedUrl);
            expect(reqParams).toEqual(params);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsSummaryData', () => {
      it('fetches value stream analytics summary data', (done) => {
        const response = [
          { value: 0, title: 'New Issues' },
          { value: 0, title: 'Deploys' },
        ];
        const params = { ...defaultParams };
        const expectedUrl = `${dummyValueStreamAnalyticsUrlRoot}/summary`;
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsSummaryData(groupId, params)
          .then((responseObj) =>
            expectRequestWithCorrectParameters(responseObj, {
              response,
              params,
              expectedUrl,
            }),
          )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsTimeSummaryData', () => {
      it('fetches value stream analytics summary data', (done) => {
        const response = [
          { value: '10.0', title: 'Lead time', unit: 'per day' },
          { value: '2.0', title: 'Cycle Time', unit: 'per day' },
        ];
        const params = { ...defaultParams };

        const expectedUrl = `${dummyValueStreamAnalyticsUrlRoot}/time_summary`;
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsTimeSummaryData(groupId, params)
          .then((responseObj) =>
            expectRequestWithCorrectParameters(responseObj, {
              response,
              params,
              expectedUrl,
            }),
          )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsValueStreams', () => {
      it('fetches custom value streams', (done) => {
        const response = [{ name: 'value stream 1', id: 1 }];
        const expectedUrl = valueStreamBaseUrl({ resource: 'value_streams' });
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsValueStreams(groupId)
          .then((responseObj) =>
            expectRequestWithCorrectParameters(responseObj, {
              response,
              expectedUrl,
            }),
          )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsCreateValueStream', () => {
      it('submit the custom value stream data', (done) => {
        const response = {};
        const customValueStream = { name: 'cool-value-stream-stage' };
        const expectedUrl = valueStreamBaseUrl({ resource: 'value_streams' });
        mock.onPost(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsCreateValueStream(groupId, customValueStream)
          .then(({ data, config: { data: reqData, url } }) => {
            expect(data).toEqual(response);
            expect(JSON.parse(reqData)).toMatchObject(customValueStream);
            expect(url).toEqual(expectedUrl);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsUpdateValueStream', () => {
      it('updates the custom value stream data', (done) => {
        const response = {};
        const customValueStream = { name: 'cool-value-stream-stage', stages: [] };
        const expectedUrl = valueStreamBaseUrl({ resource: `value_streams/${valueStreamId}` });
        mock.onPut(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsUpdateValueStream({ groupId, valueStreamId, data: customValueStream })
          .then(({ data, config: { data: reqData, url } }) => {
            expect(data).toEqual(response);
            expect(JSON.parse(reqData)).toMatchObject(customValueStream);
            expect(url).toEqual(expectedUrl);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsDeleteValueStream', () => {
      it('delete the custom value stream', (done) => {
        const response = {};
        const expectedUrl = valueStreamBaseUrl({ resource: `value_streams/${valueStreamId}` });
        mock.onDelete(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsDeleteValueStream(groupId, valueStreamId)
          .then(({ data, config: { url } }) => {
            expect(data).toEqual(response);
            expect(url).toEqual(expectedUrl);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsGroupStagesAndEvents', () => {
      it('fetches custom stage events and all stages', (done) => {
        const response = { events: [], stages: [] };
        const params = {
          group_id: groupId,
          'cycle_analytics[created_after]': createdAfter,
          'cycle_analytics[created_before]': createdBefore,
        };
        const expectedUrl = valueStreamBaseUrl({ id: valueStreamId, resource: 'stages' });
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsGroupStagesAndEvents({ groupId, valueStreamId, params })
          .then((responseObj) =>
            expectRequestWithCorrectParameters(responseObj, {
              response,
              params,
              expectedUrl,
            }),
          )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsStageEvents', () => {
      it('fetches stage events', (done) => {
        const response = { events: [] };
        const params = { ...defaultParams };
        const expectedUrl = valueStreamBaseUrl({
          id: valueStreamId,
          resource: `stages/${stageId}/records`,
        });
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsStageEvents({ groupId, valueStreamId, stageId, params })
          .then((responseObj) =>
            expectRequestWithCorrectParameters(responseObj, {
              response,
              params,
              expectedUrl,
            }),
          )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsDurationChart', () => {
      it('fetches stage duration data', (done) => {
        const response = [];
        const params = { ...defaultParams };
        const expectedUrl = valueStreamBaseUrl({
          id: valueStreamId,
          resource: `stages/${stageId}/average_duration_chart`,
        });
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsDurationChart({ groupId, valueStreamId, stageId, params })
          .then((responseObj) =>
            expectRequestWithCorrectParameters(responseObj, {
              response,
              params,
              expectedUrl,
            }),
          )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('cycleAnalyticsGroupLabels', () => {
      it('fetches group level labels', (done) => {
        const response = [];
        const expectedUrl = `${dummyUrlRoot}/groups/${groupId}/-/labels.json`;

        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        Api.cycleAnalyticsGroupLabels(groupId)
          .then(({ data, config: { url } }) => {
            expect(data).toEqual(response);
            expect(url).toEqual(expectedUrl);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('GroupActivityAnalytics', () => {
    const groupId = 'gitlab-org';

    describe('groupActivityMergeRequestsCount', () => {
      it('fetches the number of MRs created for a given group', () => {
        const response = { merge_requests_count: 10 };
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/analytics/group_activity/merge_requests_count`;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        return Api.groupActivityMergeRequestsCount(groupId).then(({ data }) => {
          expect(data).toEqual(response);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: { group_path: groupId } });
        });
      });
    });

    describe('groupActivityIssuesCount', () => {
      it('fetches the number of issues created for a given group', () => {
        const response = { issues_count: 20 };
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/analytics/group_activity/issues_count`;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, response);

        return Api.groupActivityIssuesCount(groupId).then(({ data }) => {
          expect(data).toEqual(response);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: { group_path: groupId } });
        });
      });
    });

    describe('groupActivityNewMembersCount', () => {
      it('fetches the number of new members created for a given group', () => {
        const response = { new_members_count: 30 };
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/analytics/group_activity/new_members_count`;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).reply(httpStatus.OK, response);

        return Api.groupActivityNewMembersCount(groupId).then(({ data }) => {
          expect(data).toEqual(response);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: { group_path: groupId } });
        });
      });
    });
  });

  describe('GeoReplicable', () => {
    let expectedUrl;
    let apiResponse;
    let mockParams;
    let mockReplicableType;

    beforeEach(() => {
      mockReplicableType = 'designs';
      expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/geo_replication/${mockReplicableType}`;
    });

    describe('getGeoReplicableItems', () => {
      it('fetches replicableItems based on replicableType', () => {
        apiResponse = [
          { id: 1, name: 'foo' },
          { id: 2, name: 'bar' },
        ];
        mockParams = { page: 1 };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, apiResponse);

        return Api.getGeoReplicableItems(mockReplicableType, mockParams).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl, { params: mockParams });
        });
      });
    });

    describe('initiateAllGeoReplicableSyncs', () => {
      it('POSTs with correct action', () => {
        apiResponse = [{ status: 'ok' }];
        mockParams = {};

        const mockAction = 'reverify';

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'post');
        mock.onPost(`${expectedUrl}/${mockAction}`).replyOnce(httpStatus.CREATED, apiResponse);

        return Api.initiateAllGeoReplicableSyncs(mockReplicableType, mockAction).then(
          ({ data }) => {
            expect(data).toEqual(apiResponse);
            expect(axios.post).toHaveBeenCalledWith(`${expectedUrl}/${mockAction}`, mockParams);
          },
        );
      });
    });

    describe('initiateGeoReplicableSync', () => {
      it('PUTs with correct action and projectId', () => {
        apiResponse = [{ status: 'ok' }];
        mockParams = {};

        const mockAction = 'reverify';
        const mockProjectId = 1;

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'put');
        mock
          .onPut(`${expectedUrl}/${mockProjectId}/${mockAction}`)
          .replyOnce(httpStatus.CREATED, apiResponse);

        return Api.initiateGeoReplicableSync(mockReplicableType, {
          projectId: mockProjectId,
          action: mockAction,
        }).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.put).toHaveBeenCalledWith(
            `${expectedUrl}/${mockProjectId}/${mockAction}`,
            mockParams,
          );
        });
      });
    });
  });

  describe('changeVulnerabilityState', () => {
    it.each`
      id    | action
      ${5}  | ${'dismiss'}
      ${7}  | ${'confirm'}
      ${38} | ${'resolve'}
    `('POSTS to correct endpoint ($id, $action)', ({ id, action }) => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/vulnerabilities/${id}/${action}`;
      const expectedResponse = { id, action, test: 'test' };

      mock.onPost(expectedUrl).replyOnce(httpStatus.OK, expectedResponse);

      return Api.changeVulnerabilityState(id, action).then(({ data }) => {
        expect(mock.history.post).toContainEqual(expect.objectContaining({ url: expectedUrl }));
        expect(data).toEqual(expectedResponse);
      });
    });
  });

  describe('GeoNode', () => {
    let expectedUrl;
    let mockNode;

    beforeEach(() => {
      expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/geo_nodes`;
    });

    describe('createGeoNode', () => {
      it('POSTs with correct action', () => {
        mockNode = {
          name: 'Mock Node',
          url: 'https://mock_node.gitlab.com',
          primary: false,
        };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'post');
        mock.onPost(expectedUrl).replyOnce(httpStatus.CREATED, mockNode);

        return Api.createGeoNode(mockNode).then(({ data }) => {
          expect(data).toEqual(mockNode);
          expect(axios.post).toHaveBeenCalledWith(expectedUrl, mockNode);
        });
      });
    });

    describe('updateGeoNode', () => {
      it('PUTs with correct action', () => {
        mockNode = {
          id: 1,
          name: 'Mock Node',
          url: 'https://mock_node.gitlab.com',
          primary: false,
        };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'put');
        mock.onPut(`${expectedUrl}/${mockNode.id}`).replyOnce(httpStatus.CREATED, mockNode);

        return Api.updateGeoNode(mockNode).then(({ data }) => {
          expect(data).toEqual(mockNode);
          expect(axios.put).toHaveBeenCalledWith(`${expectedUrl}/${mockNode.id}`, mockNode);
        });
      });
    });

    describe('removeGeoNode', () => {
      it('DELETES with correct ID', () => {
        mockNode = {
          id: 1,
        };

        jest.spyOn(Api, 'buildUrl').mockReturnValue(`${expectedUrl}/${mockNode.id}`);
        jest.spyOn(axios, 'delete');
        mock.onDelete(`${expectedUrl}/${mockNode.id}`).replyOnce(httpStatus.OK, {});

        return Api.removeGeoNode(mockNode.id).then(() => {
          expect(axios.delete).toHaveBeenCalledWith(`${expectedUrl}/${mockNode.id}`);
        });
      });
    });
  });

  describe('Application Settings', () => {
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/application/settings`;
    const apiResponse = { mock_setting: 1, mock_setting2: 2, mock_setting3: 3 };

    describe('getApplicationSettings', () => {
      it('fetches applications settings', () => {
        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, apiResponse);

        return Api.getApplicationSettings().then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.get).toHaveBeenCalledWith(expectedUrl);
        });
      });
    });

    describe('updateApplicationSettings', () => {
      const mockReq = { mock_setting: 10 };

      it('updates applications settings', () => {
        jest.spyOn(Api, 'buildUrl').mockReturnValue(expectedUrl);
        jest.spyOn(axios, 'put');
        mock.onPut(expectedUrl).replyOnce(httpStatus.CREATED, apiResponse);

        return Api.updateApplicationSettings(mockReq).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.put).toHaveBeenCalledWith(expectedUrl, mockReq);
        });
      });
    });
  });

  describe('Billable members list', () => {
    const namespaceId = 1000;

    describe('fetchBillableGroupMembersList', () => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${namespaceId}/billable_members`;

      it('GETs the right url', () => {
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, []);

        return Api.fetchBillableGroupMembersList(namespaceId).then(({ data }) => {
          expect(data).toEqual([]);
        });
      });
    });

    describe('fetchBillableGroupMemberMemberships', () => {
      const memberId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${namespaceId}/billable_members/${memberId}/memberships`;

      it('fetches memberships for the member', async () => {
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, []);

        const { data } = await Api.fetchBillableGroupMemberMemberships(namespaceId, memberId);

        expect(data).toEqual([]);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl);
      });
    });
  });

  describe('Project analytics: deployment frequency', () => {
    const projectPath = 'test/project';
    const encodedProjectPath = encodeURIComponent(projectPath);
    const params = { environment: 'production' };
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${encodedProjectPath}/analytics/deployment_frequency`;

    describe('deploymentFrequencies', () => {
      it('GETs the right url', async () => {
        mock.onGet(expectedUrl, { params }).replyOnce(httpStatus.OK, []);

        const { data } = await Api.deploymentFrequencies(projectPath, params);

        expect(data).toEqual([]);
      });
    });
  });

  describe('Issue metric images', () => {
    const projectId = 1;
    const issueIid = '2';
    const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectId}/issues/${issueIid}/metric_images`;

    describe('fetchIssueMetricImages', () => {
      it('fetches a list of images', async () => {
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, []);

        await Api.fetchIssueMetricImages({ issueIid, id: projectId }).then(({ data }) => {
          expect(data).toEqual([]);
          expect(axios.get).toHaveBeenCalled();
        });
      });
    });

    describe('uploadIssueMetricImage', () => {
      const file = 'mock file';
      const url = 'mock url';

      it('uploads an image', async () => {
        jest.spyOn(axios, 'post');
        mock.onPost(expectedUrl).replyOnce(httpStatus.OK, {});

        await Api.uploadIssueMetricImage({ issueIid, id: projectId, file, url }).then(
          ({ data }) => {
            expect(data).toEqual({});
            expect(axios.post.mock.calls[0][2]).toEqual({
              headers: { ...ContentTypeMultipartFormData },
            });
          },
        );
      });
    });
  });
});
