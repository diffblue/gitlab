import { GlTable, GlEmptyState, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Environments from 'ee/clusters/components/environments.vue';
import environments from './mock_data';

describe('Environments', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    const propsData = {
      environments: [],
      environmentsHelpPath: 'path/to/environments',
      clustersHelpPath: 'path/to/clusters',
      deployBoardsHelpPath: 'path/to/clusters',
      isFetching: false,
    };

    wrapper = mount(Environments, {
      propsData: { ...propsData, environments, ...props },
      stubs: { deploymentInstance: { template: '<div class="js-deployment-instance"></div>' } },
    });
  };

  it('renders an empty state if no deployments are found', () => {
    createComponent({ environments: [] });

    const emptyState = wrapper.findComponent(GlEmptyState);
    const emptyStateText = emptyState.text().replace(/\s+/g, ' ');

    expect(emptyState.exists()).toBe(true);
    expect(emptyStateText).toContain(
      'No deployments found Ensure your environment is part of the deploy stage of your CI pipeline to track deployments to your cluster.',
    );
    expect(emptyStateText).toContain('Learn more about deploying to a cluster');
  });

  describe('environments table', () => {
    let table;

    beforeEach(() => {
      createComponent();
      table = wrapper.findComponent(GlTable);
    });

    it('renders a table component', () => {
      expect(table.exists()).toBe(true);
    });

    it('renders the correct table headers', () => {
      const tableHeaders = ['Project', 'Environment', 'Job', `Pods in use  2`, 'Last updated'];
      const headers = table.findAll('th');

      expect(headers).toHaveLength(tableHeaders.length);

      tableHeaders.forEach((headerText, i) => expect(headers.at(i).text()).toEqual(headerText));
    });

    it('should stack on smaller devices', () => {
      expect(table.classes()).toContain('b-table-stacked-md');
    });

    describe('deployment instances', () => {
      let tableRows;

      beforeEach(() => {
        createComponent();
        table = wrapper.findComponent(GlTable);
        tableRows = table.findAll('tbody tr');
      });

      it('renders a loader if the rollout status is loading', () => {
        environments.forEach((environment, i) => {
          const { status } = environment.rolloutStatus;

          if (status === 'loading') {
            const loader = tableRows.at(i).findComponent(GlLoadingIcon);

            expect(loader.exists()).toBe(true);
          }
        });
      });

      it('renders deployment instances', () => {
        environments.forEach((environment, i) => {
          const { instances } = environment.rolloutStatus;

          expect(tableRows.at(i).findAll('.js-deployment-instance')).toHaveLength(instances.length);
        });
      });

      it('renders an empty state if no deployment instances are found', () => {
        const emptyStateText =
          'Deploy progress not found. To see pods, ensure your environment matches deploy board criteria.';

        environments.forEach((environment, i) => {
          const { status, instances } = environment.rolloutStatus;

          if (status !== 'loading' && instances.length === 0) {
            const emptyState = tableRows.at(i).find('.deployments-empty');
            const emptyStateIcon = emptyState.findComponent(GlIcon);

            expect(emptyState.exists()).toBe(true);
            expect(emptyStateIcon.exists()).toBe(true);
            expect(emptyState.text()).toEqual(emptyStateText);
            expect(emptyStateIcon.props().name).toEqual('warning');
          }
        });
      });
    });
  });
});
