import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { merge } from 'lodash';
import dastProfilesMock from 'test_fixtures/graphql/on_demand_scans/graphql/dast_profiles.query.graphql.json';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SavedTab from 'ee/on_demand_scans/components/tabs/saved.vue';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import dastProfilesQuery from 'ee/on_demand_scans/graphql/dast_profiles.query.graphql';
import { createRouter } from 'ee/on_demand_scans/router';
import { SAVED_TAB_TABLE_FIELDS, LEARN_MORE_TEXT } from 'ee/on_demand_scans/constants';
import { s__ } from '~/locale';
import ScanTypeBadge from 'ee/security_configuration/dast_profiles/components/dast_scan_type_badge.vue';

jest.mock('~/lib/utils/common_utils');

Vue.use(VueApollo);

describe('Saved tab', () => {
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
    return createMockApollo([[dastProfilesQuery, requestHandler]]);
  };

  const createComponentFactory = (mountFn = shallowMountExtended) => (options = {}) => {
    router = createRouter();
    wrapper = mountFn(
      SavedTab,
      merge(
        {
          apolloProvider: createMockApolloProvider(),
          router,
          propsData: {
            isActive: true,
            itemsCount,
          },
          provide: {
            projectPath,
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
    requestHandler = jest.fn().mockResolvedValue(dastProfilesMock);
  });

  afterEach(() => {
    wrapper.destroy();
    router = null;
    requestHandler = null;
  });

  it('renders the base tab with the correct props', () => {
    createComponent();

    expect(findBaseTab().props('title')).toBe(s__('OnDemandScans|Scan library'));
    expect(findBaseTab().props('itemsCount')).toBe(itemsCount);
    expect(findBaseTab().props('query')).toBe(dastProfilesQuery);
    expect(findBaseTab().props('emptyStateTitle')).toBe(
      s__('OnDemandScans|There are no saved scans.'),
    );
    expect(findBaseTab().props('emptyStateText')).toBe(LEARN_MORE_TEXT);
    expect(findBaseTab().props('fields')).toBe(SAVED_TAB_TABLE_FIELDS);
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
    const [firstProfile] = dastProfilesMock.data.project.pipelines.nodes;

    beforeEach(() => {
      createFullComponent();
    });

    it('renders the branch name in the name cell', () => {
      const nameCell = findCellAt(0);

      expect(nameCell.text()).toContain(firstProfile.branch.name);
    });

    it('renders the scan type', () => {
      const firstScanTypeBadge = wrapper.findComponent(ScanTypeBadge);

      expect(firstScanTypeBadge.exists()).toBe(true);
      expect(firstScanTypeBadge.props('scanType')).toBe(firstProfile.dastScannerProfile.scanType);
    });
  });
});
