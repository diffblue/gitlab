import {
  DEFAULT_MEMBERSHIP,
  DEFAULT_SORT,
  INSTANCE_TYPE,
  CREATED_ASC,
  RUNNER_PAGE_SIZE,
} from '~/ci/runner/constants';
import { UPGRADE_STATUS_AVAILABLE } from 'ee/ci/runner/constants';

import { mockSearchExamples } from 'jest/ci/runner/mock_data';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from 'ee/ci/runner/runner_search_utils';

describe('ee search_params.js', () => {
  const examples = [
    ...mockSearchExamples,
    {
      name: 'a single upgrade status',
      urlQuery: '?upgrade_status[]=AVAILABLE',
      search: {
        runnerType: null,
        membership: DEFAULT_MEMBERSHIP,
        filters: [
          { type: 'upgrade_status', value: { data: UPGRADE_STATUS_AVAILABLE, operator: '=' } },
        ],
        pagination: {},
        sort: DEFAULT_SORT,
      },
      graphqlVariables: {
        upgradeStatus: UPGRADE_STATUS_AVAILABLE,
        membership: DEFAULT_MEMBERSHIP,
        sort: DEFAULT_SORT,
        first: RUNNER_PAGE_SIZE,
      },
    },
    {
      name: 'upgrade status, a single instance type and a non default sort',
      urlQuery: '?runner_type[]=INSTANCE_TYPE&upgrade_status[]=AVAILABLE&sort=CREATED_ASC',
      search: {
        runnerType: INSTANCE_TYPE,
        membership: DEFAULT_MEMBERSHIP,
        filters: [
          { type: 'upgrade_status', value: { data: UPGRADE_STATUS_AVAILABLE, operator: '=' } },
        ],
        pagination: {},
        sort: CREATED_ASC,
      },
      graphqlVariables: {
        upgradeStatus: UPGRADE_STATUS_AVAILABLE,
        type: INSTANCE_TYPE,
        membership: DEFAULT_MEMBERSHIP,
        sort: CREATED_ASC,
        first: RUNNER_PAGE_SIZE,
      },
    },
  ];

  describe('fromUrlQueryToSearch', () => {
    examples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a search object`, () => {
        expect(fromUrlQueryToSearch(urlQuery)).toEqual(search);
      });
    });
  });

  describe('fromSearchToUrl', () => {
    examples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a url`, () => {
        expect(fromSearchToUrl(search)).toBe(`http://test.host/${urlQuery}`);
      });
    });

    it.each(['http://test.host/?upgrade_status[]=AVAILABLE'])(
      'When a filter is removed, it is removed from the URL',
      (initalUrl) => {
        const search = { filters: [], sort: DEFAULT_SORT };
        const expectedUrl = `http://test.host/`;

        expect(fromSearchToUrl(search, initalUrl)).toBe(expectedUrl);
      },
    );

    it('When unrelated search parameter is present, it does not get removed', () => {
      const initialUrl = `http://test.host/?unrelated=UNRELATED&upgrade_status[]=AVAILABLE`;
      const search = { filters: [], sort: DEFAULT_SORT };
      const expectedUrl = `http://test.host/?unrelated=UNRELATED`;

      expect(fromSearchToUrl(search, initialUrl)).toBe(expectedUrl);
    });
  });

  describe('fromSearchToVariables', () => {
    examples.forEach(({ name, graphqlVariables, search }) => {
      it(`Converts ${name} to a GraphQL query variables object`, () => {
        expect(fromSearchToVariables(search)).toEqual(graphqlVariables);
      });
    });
  });
});
