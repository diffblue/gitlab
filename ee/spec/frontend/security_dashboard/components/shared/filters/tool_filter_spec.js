import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import createFlash from '~/flash';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ToolFilter from 'ee/security_dashboard/components/shared/filters/tool_filter.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilterBody from 'ee/security_dashboard/components/shared/filters/filter_body.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { simpleScannerFilter, getFormattedScanners } from 'ee/security_dashboard/helpers';
import projectScannersQuery from 'ee/security_dashboard/graphql/queries/project_specific_scanners.query.graphql';
import groupScannersQuery from 'ee/security_dashboard/graphql/queries/group_specific_scanners.query.graphql';
import instanceScannersQuery from 'ee/security_dashboard/graphql/queries/instance_specific_scanners.query.graphql';
import { TOOL_FILTER_ERROR } from 'ee/security_dashboard/components/shared/filters/constants';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import {
  projectVulnerabilityScanners,
  groupVulnerabilityScanners,
  instanceVulnerabilityScanners,
} from '../../mock_data';

jest.mock('~/flash');

describe('Tool Filter component', () => {
  let wrapper;
  let filter;

  const fullPath = 'test/path';
  const projectScannersResolver = jest.fn().mockResolvedValue(projectVulnerabilityScanners);
  const groupScannersResolver = jest.fn().mockResolvedValue(groupVulnerabilityScanners);
  const instanceScannersResolver = jest.fn().mockResolvedValue(instanceVulnerabilityScanners);
  const defaultQuery = projectScannersQuery;
  const defaultResolver = projectScannersResolver;
  const defaultFormattedScanners = getFormattedScanners(
    projectVulnerabilityScanners.data.project.vulnerabilityScanners.nodes,
  );
  const defaultProvide = {
    fullPath,
    dashboardType: DASHBOARD_TYPES.PROJECT,
  };

  const createMockApolloProvider = (query = defaultQuery, resolver = defaultResolver) => {
    Vue.use(VueApollo);
    return createMockApollo([[query, resolver]]);
  };

  const createWrapper = ({ query, resolver, provide } = {}) => {
    filter = cloneDeep(simpleScannerFilter);

    wrapper = shallowMountExtended(ToolFilter, {
      propsData: { filter },
      apolloProvider: createMockApolloProvider(query, resolver),
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });

    return waitForPromises();
  };

  const findFilterBody = () => wrapper.findComponent(FilterBody);
  const findFilterItems = () => wrapper.findAllComponents(FilterItem);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('basic structure', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('provides the correct props to the FilterBody component', () => {
      const { name, allOption } = filter;

      expect(findFilterBody().props()).toMatchObject({
        name,
        selectedOptions: [allOption],
      });
    });

    it('displays the all option item', () => {
      const { allOption } = filter;

      expect(findFilterItems().at(0).props()).toStrictEqual({
        isChecked: true,
        text: allOption.name,
        truncate: false,
      });
    });

    it('displays loading state', () => {
      expect(findFilterBody().props('loading')).toBe(true);
    });
  });

  describe('successful query request', () => {
    it('does not display the loading state', async () => {
      await createWrapper();

      expect(findFilterBody().props('loading')).toBe(false);
    });

    it.each`
      dashboardType               | query                    | resolver                    | argument
      ${DASHBOARD_TYPES.PROJECT}  | ${projectScannersQuery}  | ${projectScannersResolver}  | ${fullPath}
      ${DASHBOARD_TYPES.GROUP}    | ${groupScannersQuery}    | ${groupScannersResolver}    | ${fullPath}
      ${DASHBOARD_TYPES.INSTANCE} | ${instanceScannersQuery} | ${instanceScannersResolver} | ${undefined}
    `(
      'makes the query request for $dashboardType',
      async ({ dashboardType, query, resolver, argument }) => {
        await createWrapper({ query, resolver, provide: { dashboardType } });

        expect(resolver).toHaveBeenCalledTimes(1);
        expect(resolver.mock.calls[0][0]).toEqual({ fullPath: argument });
      },
    );

    it('renders the correct amount of filter options', async () => {
      const allOptionCount = 1;
      const totalOptionsCount = defaultFormattedScanners.length + allOptionCount;

      await createWrapper();

      expect(findFilterItems()).toHaveLength(totalOptionsCount);
    });

    it('populates the filter options from the query response', async () => {
      await createWrapper();

      defaultFormattedScanners.forEach(({ name }, index) => {
        expect(
          findFilterItems()
            .at(index + 1)
            .props(),
        ).toStrictEqual({ isChecked: false, text: name, truncate: false });
      });
    });
  });

  describe('unsuccessful query request', () => {
    it('shows an alert', async () => {
      const errorSpy = jest.fn().mockRejectedValue();

      await createWrapper({ resolver: errorSpy });

      expect(createFlash).toHaveBeenCalledWith({ message: TOOL_FILTER_ERROR });
    });

    it('skips the query for invalid dashboard type', async () => {
      await createWrapper({ provide: { dashboardType: 'foo' } });

      expect(defaultResolver).not.toHaveBeenCalled();
    });
  });
});
