import { GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import IssuesAnalyticsTable from 'ee/issues_analytics/components/issues_analytics_table.vue';
import getIssuesAnalyticsData from 'ee/issues_analytics/graphql/queries/issues_analytics.query.graphql';
import {
  mockIssuesApiResponse,
  tableHeaders,
  endpoints,
  getQueryIssuesAnalyticsResponse,
} from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('IssuesAnalyticsTable', () => {
  let wrapper;
  let fakeApollo;

  const getQueryIssuesAnalyticsSuccess = jest
    .fn()
    .mockResolvedValue(getQueryIssuesAnalyticsResponse);

  const createComponent = ({
    apolloHandlers = [getIssuesAnalyticsData, getQueryIssuesAnalyticsSuccess],
    type = 'group',
  } = {}) => {
    fakeApollo = createMockApollo([apolloHandlers]);

    wrapper = mount(IssuesAnalyticsTable, {
      apolloProvider: fakeApollo,
      provide: { fullPath: 'gitlab-org', type },
      propsData: {
        endpoints,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  const findIssueDetailsCol = (rowIndex) =>
    findTable().findAll('[data-testid="detailsCol"]').at(rowIndex);

  const findIterationCol = (rowIndex) =>
    findTable().findAll('[data-testid="iterationCol"]').at(rowIndex);

  const findAgeCol = (rowIndex) => findTable().findAll('[data-testid="ageCol"]').at(rowIndex);

  const findStatusCol = (rowIndex) => findTable().findAll('[data-testid="statusCol"]').at(rowIndex);

  beforeEach(() => {
    jest.spyOn(Date, 'now').mockImplementation(() => new Date('2020-01-08'));
  });

  afterEach(() => {
    fakeApollo = null;
  });

  describe('while fetching data', () => {
    beforeEach(async () => {
      createComponent({ apolloHandlers: [getIssuesAnalyticsData, () => new Promise(() => {})] });
      await nextTick();
    });

    it('displays a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not display the table', () => {
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('fetching data completed', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('hides the loading state', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });

    it('displays the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    describe('table data and formatting', () => {
      it('displays the correct table headers', () => {
        const headers = findTable().findAll('[data-testid="header"]');

        expect(headers).toHaveLength(tableHeaders.length);

        tableHeaders.forEach((headerText, i) => expect(headers.at(i).text()).toEqual(headerText));
      });

      it('displays the correct issue details', () => {
        const { title, iid, epic } = mockIssuesApiResponse[0];

        expect(findIssueDetailsCol(0).text()).toBe(`${title} #${iid} &${epic.iid}`);
      });

      it('displays the correct issue details labels', () => {
        const { iid } = mockIssuesApiResponse[1];
        const firstDetails = findIssueDetailsCol(1);
        const labelsId = firstDetails.findComponent('[data-testid="labels"]').attributes('id');
        const labelsPopoverTarget = firstDetails
          .findComponent('[data-testid="labelsPopover"]')
          .props('target');

        expect(labelsId).toBe(`${iid}-labels`);
        expect(labelsId).toBe(labelsPopoverTarget);
      });

      it('displays the correct issue iteration', () => {
        expect(findIterationCol(0).text()).toBe('');
        expect(findIterationCol(2).text()).toBe('Iteration 1');
      });

      it('displays the correct issue age', () => {
        expect(findAgeCol(0).text()).toBe('0 days');
        expect(findAgeCol(1).text()).toBe('1 day');
        expect(findAgeCol(2).text()).toBe('2 days');
      });

      it('capitalizes the status', () => {
        expect(findStatusCol(0).text()).toBe('Closed');
      });
    });
  });

  describe('query', () => {
    it.each(['group', 'project'])(
      'calls the query with the correct variables when the the type is "%s"',
      (type) => {
        createComponent({ type });

        expect(getQueryIssuesAnalyticsSuccess).toHaveBeenCalledWith({
          fullPath: 'gitlab-org',
          isGroup: type === 'group',
          isProject: type === 'project',
        });
      },
    );
  });

  describe('error fetching data', () => {
    beforeEach(async () => {
      createComponent({ apolloHandlers: [getIssuesAnalyticsData, jest.fn().mockRejectedValue()] });
      await nextTick();
    });

    it('displays an error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to load issues. Please try again.',
      });
    });
  });
});
