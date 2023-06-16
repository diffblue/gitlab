import { GlCollapsibleListbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import ClusterFilter from 'ee/security_dashboard/components/shared/filters/cluster_filter.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
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
  const firstMockClusterName = mockClusters[0].name;

  const createWrapper = (queryResolver = defaultQueryResolver) => {
    wrapper = mountExtended(ClusterFilter, {
      apolloProvider: createMockApollo([[clusterAgents, queryResolver]]),
      provide: { projectFullPath: 'test/path' },
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = (name) => wrapper.findByTestId(`listbox-item-${name}`);

  const clickListboxItem = (name) => {
    return findListboxItem(name).trigger('click');
  };

  const expectSelectedItems = (ids) => {
    expect(findListbox().props('selected')).toEqual(ids);
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
        ${[firstMockClusterName]} | ${[firstMockClusterName]}
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

      it('shows the listbox with correct header text', () => {
        expect(findListbox().props('headerText')).toBe(ClusterFilter.i18n.label);
      });

      it(`passes '${firstMockClusterName}' when only ${firstMockClusterName} is selected`, async () => {
        await clickListboxItem(firstMockClusterName);

        expect(findListbox().props('toggleText')).toBe(firstMockClusterName);
      });

      it(`passes '${firstMockClusterName} +1 more' when ${firstMockClusterName} and another image is selected`, async () => {
        await clickListboxItem(firstMockClusterName);
        await clickListboxItem(mockClusters[1].name);

        expect(findListbox().props('toggleText')).toBe(`${firstMockClusterName} +1 more`);
      });

      it(`passes "${ClusterFilter.i18n.allItemsText}" when no option is selected`, () => {
        expect(findListbox().props('toggleText')).toBe(ClusterFilter.i18n.allItemsText);
      });
    });

    describe('filter-changed event', () => {
      const getLastEmittedClusterAgentId = () => {
        return wrapper.emitted('filter-changed').at(-1)[0].clusterAgentId;
      };

      it('emits filter-changed event when selected item is changed', async () => {
        const ids = [];
        await clickListboxItem(ALL_ID);

        expect(getLastEmittedClusterAgentId()).toEqual([]);

        for await (const { id, name } of mockClusters) {
          await clickListboxItem(name);
          ids.push(id);

          expect(getLastEmittedClusterAgentId()).toEqual(ids);
        }
      });

      it('emits filter-changed event when item was selected with querystring sync', async () => {
        createWrapper();

        // First emit is empty because `getClusterAgents` query has not returned yet to match
        expect(getLastEmittedClusterAgentId()).toEqual([]);

        wrapper.findComponent(QuerystringSync).vm.$emit('input', [mockClusters[0].name]);
        await waitForPromises();

        expect(getLastEmittedClusterAgentId()).toEqual([mockClusters[0].id]);
      });
    });

    describe('listbox items', () => {
      it('populates all dropdown items with correct text', () => {
        expect(findListbox().props('items')).toHaveLength(mockClusters.length + 1);
        expect(findListboxItem(ALL_ID).text()).toBe(ClusterFilter.i18n.allItemsText);

        mockClusters.forEach(({ name }) => {
          expect(findListboxItem(name).text()).toBe(name);
        });
      });

      it('allows multiple items to be selected', async () => {
        const names = [];

        for await (const { name } of mockClusters) {
          await clickListboxItem(name);
          names.push(name);

          expectSelectedItems(names);
        }
      });

      it('toggles the item selection when clicked on', async () => {
        for await (const { name } of mockClusters) {
          await clickListboxItem(name);

          expectSelectedItems([name]);

          await clickListboxItem(name);

          expectSelectedItems([ALL_ID]);
        }
      });

      it('selects ALL item when created', () => {
        expectSelectedItems([ALL_ID]);
      });

      it('selects ALL item and deselects everything else when it is clicked', async () => {
        await clickListboxItem(ALL_ID);
        await clickListboxItem(ALL_ID); // Click again to verify that it doesn't toggle.

        expectSelectedItems([ALL_ID]);
      });

      it('deselects the ALL item when another item is clicked', async () => {
        await clickListboxItem(ALL_ID);
        await clickListboxItem(firstMockClusterName);

        expectSelectedItems([firstMockClusterName]);
      });
    });
  });

  it('shows an alert on a failed GraphQL request', async () => {
    createWrapper(jest.fn().mockRejectedValue());
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: ClusterFilter.i18n.loadingError });
  });
});
