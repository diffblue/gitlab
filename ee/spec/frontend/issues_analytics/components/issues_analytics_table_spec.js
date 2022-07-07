import { GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import IssuesAnalyticsTable from 'ee/issues_analytics/components/issues_analytics_table.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import httpStatusCodes from '~/lib/utils/http_status';
import { mockIssuesApiResponse, tableHeaders, endpoints } from '../mock_data';

jest.mock('~/flash');

describe('IssuesAnalyticsTable', () => {
  let wrapper;
  let mock;

  const createComponent = () => {
    return mount(IssuesAnalyticsTable, {
      propsData: {
        endpoints,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  const findIssueDetailsCol = (rowIndex) =>
    findTable().findAll('[data-testid="detailsCol"]').at(rowIndex);

  const findAgeCol = (rowIndex) => findTable().findAll('[data-testid="ageCol"]').at(rowIndex);

  const findStatusCol = (rowIndex) => findTable().findAll('[data-testid="statusCol"]').at(rowIndex);

  beforeEach(() => {
    jest.spyOn(Date, 'now').mockImplementation(() => new Date('2020-01-08'));

    mock = new MockAdapter(axios);
    mock.onGet().reply(httpStatusCodes.OK, mockIssuesApiResponse);

    wrapper = createComponent();

    return waitForPromises();
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('while fetching data', () => {
    it('displays a loading icon', () => {
      wrapper = createComponent();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not display the table', () => {
      wrapper = createComponent();

      expect(findTable().exists()).toBe(false);
    });
  });

  describe('fetching data completed', () => {
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

  describe('error fetching data', () => {
    beforeEach(() => {
      mock.onGet().reply(httpStatusCodes.NOT_FOUND, mockIssuesApiResponse);
      wrapper = createComponent();

      return waitForPromises();
    });

    it('displays an error', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Failed to load issues. Please try again.',
      });
    });
  });
});
