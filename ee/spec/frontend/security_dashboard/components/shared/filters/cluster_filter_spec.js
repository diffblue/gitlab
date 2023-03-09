import { GlDropdown } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import ClusterFilter from 'ee/security_dashboard/components/shared/filters/cluster_filter.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import clusterAgents from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import { projectClusters } from '../../mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('ClusterFilter component', () => {
  let wrapper;
  const defaultQueryResolver = jest.fn().mockResolvedValue(projectClusters);
  const mockClusters = projectClusters.data.project.clusterAgents.nodes;

  const createWrapper = (queryResolver = defaultQueryResolver) => {
    wrapper = mountExtended(ClusterFilter, {
      apolloProvider: createMockApollo([[clusterAgents, queryResolver]]),
      provide: { projectFullPath: 'test/path' },
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findDropdownItems = () => wrapper.findAllComponents(FilterItem);
  const findDropdownItem = (name) => wrapper.findByTestId(name);

  const clickDropdownItem = async (name) => {
    findDropdownItem(name).trigger('click');
    await nextTick();
  };

  const expectSelectedItems = (ids) => {
    const checkedItems = findDropdownItems()
      .wrappers.filter((item) => item.props('isChecked'))
      .map((item) => item.attributes('data-testid'));

    expect(checkedItems).toEqual(ids);
  };

  describe('basic structure', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    describe('QuerystringSync component', () => {
      it('has expected props', () => {
        expect(findQuerystringSync().props()).toMatchObject({
          querystringKey: 'cluster',
          value: [],
        });
      });

      it.each`
        emitted                   | expected
        ${[]}                     | ${[ALL_ID]}
        ${[mockClusters[0].name]} | ${[mockClusters[0].name]}
      `('restores selected items - $emitted', async ({ emitted, expected }) => {
        findQuerystringSync().vm.$emit('input', emitted);
        await nextTick();

        expectSelectedItems(expected);
      });
    });

    describe('default view', () => {
      it('shows the label', () => {
        expect(wrapper.find('label').text()).toBe(ClusterFilter.i18n.label);
      });

      it('shows the dropdown with correct header text', () => {
        expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe(
          ClusterFilter.i18n.label,
        );
      });

      it('shows the DropdownButtonText component with the correct props', () => {
        expect(wrapper.findComponent(DropdownButtonText).props()).toMatchObject({
          items: [ClusterFilter.i18n.allItemsText],
          name: ClusterFilter.i18n.label,
        });
      });
    });

    describe('filter-changed event', () => {
      it('emits filter-changed event when selected item is changed', async () => {
        const ids = [];
        await clickDropdownItem(ALL_ID);

        expect(wrapper.emitted('filter-changed')[0][0].clusterAgentId).toEqual([]);

        for await (const { id, name } of mockClusters) {
          await clickDropdownItem(name);
          ids.push(id);

          expect(wrapper.emitted('filter-changed')[ids.length][0].clusterAgentId).toEqual(ids);
        }
      });
    });

    describe('dropdown items', () => {
      it('populates all dropdown items with correct text', () => {
        expect(findDropdownItems()).toHaveLength(mockClusters.length + 1);
        expect(findDropdownItem(ALL_ID).text()).toBe(ClusterFilter.i18n.allItemsText);

        mockClusters.forEach(({ name }) => {
          expect(findDropdownItem(name).text()).toBe(name);
        });
      });

      it('allows multiple items to be selected', async () => {
        const names = [];

        for await (const { name } of mockClusters) {
          await clickDropdownItem(name);
          names.push(name);

          expectSelectedItems(names);
        }
      });

      it('toggles the item selection when clicked on', async () => {
        for await (const { name } of mockClusters) {
          await clickDropdownItem(name);

          expectSelectedItems([name]);

          await clickDropdownItem(name);

          expectSelectedItems([ALL_ID]);
        }
      });

      it('selects ALL item when created', () => {
        expectSelectedItems([ALL_ID]);
      });

      it('selects ALL item and deselects everything else when it is clicked', async () => {
        await clickDropdownItem(ALL_ID);
        await clickDropdownItem(ALL_ID); // Click again to verify that it doesn't toggle.

        expectSelectedItems([ALL_ID]);
      });

      it('deselects the ALL item when another item is clicked', async () => {
        await clickDropdownItem(ALL_ID);
        await clickDropdownItem(mockClusters[0].name);

        expectSelectedItems([mockClusters[0].name]);
      });
    });
  });

  it('shows an alert on a failed GraphQL request', async () => {
    createWrapper(jest.fn().mockRejectedValue());
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: ClusterFilter.i18n.loadingError });
  });
});
