import MockAdapter from 'axios-mock-adapter';
import { createMockClient } from 'mock-apollo-client';
import { createResolvers } from 'ee/analytics/devops_reports/devops_adoption/graphql';
import getGroupsQuery from 'ee/analytics/devops_reports/devops_adoption/graphql/queries/get_groups.query.graphql';
import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { groupData, groupNodes } from '../mock_data';

const fetchGroupsUrl = Api.buildUrl(Api.groupsPath);
const fetchSubGroupsUrl = Api.buildUrl(Api.subgroupsPath).replace(':id', 1);

describe('DevOps GraphQL resolvers', () => {
  let mockAdapter;
  let mockClient;

  describe.each`
    type       | groupId | url
    ${'group'} | ${1}    | ${fetchSubGroupsUrl}
    ${'admin'} | ${null} | ${fetchGroupsUrl}
  `('$type view query', ({ groupId, url }) => {
    beforeEach(() => {
      mockAdapter = new MockAdapter(axios);
      mockClient = createMockClient({ resolvers: createResolvers(groupId) });
    });

    afterEach(() => {
      mockAdapter.restore();
    });

    it('fetches all relevent groups / subgroups', async () => {
      mockAdapter.onGet(url).reply(HTTP_STATUS_OK, groupData);
      await mockClient.query({ query: getGroupsQuery });

      expect(mockAdapter.history.get[0].params).not.toEqual(
        expect.objectContaining({ top_level_only: true }),
      );
    });

    it('when receiving groups data', async () => {
      mockAdapter.onGet(url).reply(HTTP_STATUS_OK, groupData);
      const result = await mockClient.query({ query: getGroupsQuery });

      expect(result.data).toEqual({
        groups: {
          __typename: 'Groups',
          nodes: groupNodes,
        },
      });
    });

    it('when receiving empty groups data', async () => {
      mockAdapter.onGet(url).reply(HTTP_STATUS_OK, []);
      const result = await mockClient.query({ query: getGroupsQuery });

      expect(result.data).toEqual({
        groups: {
          __typename: 'Groups',
          nodes: [],
        },
      });
    });
  });
});
