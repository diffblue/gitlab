import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { merge, cloneDeep } from 'lodash';
import mockTimezones from 'test_fixtures/timezones/abbr.json';
import scheduledDastProfilesMock from 'test_fixtures/graphql/on_demand_scans/graphql/scheduled_dast_profiles.query.graphql.json';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ScheduledTab from 'ee/on_demand_scans/components/tabs/scheduled.vue';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import scheduledDastProfilesQuery from 'ee/on_demand_scans/graphql/scheduled_dast_profiles.query.graphql';
import { createRouter } from 'ee/on_demand_scans/router';
import {
  SCHEDULED_TAB_TABLE_FIELDS,
  LEARN_MORE_TEXT,
  MAX_DAST_PROFILES_COUNT,
} from 'ee/on_demand_scans/constants';
import { __, s__ } from '~/locale';
import { stripTimezoneFromISODate } from '~/lib/utils/datetime/date_format_utility';
import DastScanSchedule from 'ee/security_configuration/dast_profiles/components/dast_scan_schedule.vue';
import { PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK } from '../../mocks';

jest.mock('~/lib/utils/common_utils');

Vue.use(VueApollo);

describe('Scheduled tab', () => {
  let wrapper;
  let router;
  let requestHandler;

  // Props
  const projectPath = '/namespace/project';
  const itemsCount = 12;

  // Finders
  const findBaseTab = () => wrapper.findComponent(BaseTab);
  const findFirstRow = () => wrapper.find('tbody > tr');
  const findCellAt = (index) => findFirstRow().findAll('td').at(index);

  // Helpers
  const createMockApolloProvider = () => {
    return createMockApollo([[scheduledDastProfilesQuery, requestHandler]]);
  };

  const createComponentFactory = (mountFn = shallowMountExtended) => (options = {}) => {
    router = createRouter();
    wrapper = mountFn(
      ScheduledTab,
      merge(
        {
          apolloProvider: createMockApolloProvider(),
          router,
          propsData: {
            isActive: true,
            itemsCount,
          },
          provide: {
            canEditOnDemandScans: false,
            projectPath,
            projectOnDemandScanCountsEtag: PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK,
            timezones: mockTimezones,
          },
          stubs: {
            BaseTab,
          },
        },
        options,
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mountExtended);

  beforeEach(() => {
    requestHandler = jest.fn().mockResolvedValue(scheduledDastProfilesMock);
  });

  afterEach(() => {
    router = null;
    requestHandler = null;
  });

  it('renders the base tab with the correct props', () => {
    createComponent();

    expect(cloneDeep(findBaseTab().props())).toEqual({
      isActive: true,
      title: __('Scheduled'),
      itemsCount,
      maxItemsCount: MAX_DAST_PROFILES_COUNT,
      query: scheduledDastProfilesQuery,
      queryVariables: {},
      emptyStateTitle: s__('OnDemandScans|There are no scheduled scans.'),
      emptyStateText: LEARN_MORE_TEXT,
      fields: SCHEDULED_TAB_TABLE_FIELDS,
    });
  });

  it('fetches the profiles', () => {
    createComponent();

    expect(requestHandler).toHaveBeenCalledWith({
      after: null,
      before: null,
      first: 20,
      fullPath: projectPath,
      last: null,
    });
  });

  describe('custom table cells', () => {
    const [firstProfile] = scheduledDastProfilesMock.data.project.pipelines.nodes;

    beforeEach(async () => {
      createFullComponent();
      await waitForPromises();
    });

    it('renders the next run cell', () => {
      const nextRunCell = findCellAt(4);

      expect(nextRunCell.text()).toContain(
        new Date(firstProfile.dastProfileSchedule.nextRunAt).toLocaleDateString(
          window.navigator.language,
          {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
          },
        ),
      );
      expect(nextRunCell.text()).toContain(
        new Date(
          stripTimezoneFromISODate(firstProfile.dastProfileSchedule.startsAt),
        ).toLocaleTimeString(window.navigator.language, {
          hour: '2-digit',
          minute: '2-digit',
        }),
      );
    });

    it('renders the schedule cell', () => {
      const scheduleCell = findCellAt(5);
      const dastScanScheduleComponent = scheduleCell.findComponent(DastScanSchedule);

      expect(dastScanScheduleComponent.exists()).toBe(true);
      expect(dastScanScheduleComponent.props('schedule')).toEqual(firstProfile.dastProfileSchedule);
    });
  });
});
