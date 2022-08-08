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
import { vendorScannerFilter, getFormattedScanners } from 'ee/security_dashboard/helpers';
import projectScannersQuery from 'ee/security_dashboard/graphql/queries/project_specific_scanners.query.graphql';
import { TOOL_FILTER_ERROR } from 'ee/security_dashboard/components/shared/filters/constants';
import { projectVulnerabilityScanners } from '../../mock_data';

jest.mock('~/flash');

describe('Tool Filter component', () => {
  let wrapper;
  let filter;

  const projectFullPath = 'test/path';
  const projectVulnerabilityScannersNodes =
    projectVulnerabilityScanners.data.project.vulnerabilityScanners.nodes;
  const formattedProjectScanners = getFormattedScanners(projectVulnerabilityScannersNodes);
  const defaultQueryResolver = jest.fn().mockResolvedValue(projectVulnerabilityScanners);

  const createMockApolloProvider = (queryResolver = defaultQueryResolver) => {
    Vue.use(VueApollo);
    return createMockApollo([[projectScannersQuery, queryResolver]]);
  };

  const createWrapper = (queryResolver) => {
    filter = cloneDeep(vendorScannerFilter);

    wrapper = shallowMountExtended(ToolFilter, {
      propsData: { filter },
      apolloProvider: createMockApolloProvider(queryResolver),
      provide: { projectFullPath },
    });
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
      });
    });

    it('displays loading state', () => {
      expect(findFilterBody().props('loading')).toBe(true);
    });
  });

  describe('successful query request', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('does not display the loading state', () => {
      expect(findFilterBody().props('loading')).toBe(false);
    });

    it('makes the query request', () => {
      expect(defaultQueryResolver).toHaveBeenCalledTimes(1);
      expect(defaultQueryResolver.mock.calls[0][0]).toEqual({ fullPath: projectFullPath });
    });

    it('renders the correct amount of filter options', () => {
      const allOptionCount = 1;
      const totalOptionsCount = formattedProjectScanners.length + allOptionCount;

      expect(findFilterItems()).toHaveLength(totalOptionsCount);
    });

    it('populates the filter options from the query response', () => {
      formattedProjectScanners.forEach(({ name }, index) => {
        expect(
          findFilterItems()
            .at(index + 1)
            .props(),
        ).toStrictEqual({ isChecked: false, text: name });
      });
    });
  });

  describe('failed query request', () => {
    it('shows an alert', async () => {
      const errorSpy = jest.fn().mockRejectedValue();

      createWrapper(errorSpy);
      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({ message: TOOL_FILTER_ERROR });
    });
  });
});
