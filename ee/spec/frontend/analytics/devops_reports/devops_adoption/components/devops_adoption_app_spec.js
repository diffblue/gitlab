import { GlAlert, GlTabs } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import DevopsAdoptionAddDropdown from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_add_dropdown.vue';
import DevopsAdoptionApp from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_app.vue';
import DevopsAdoptionOverview from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_overview.vue';
import DevopsAdoptionSection from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_section.vue';
import {
  I18N_GROUPS_QUERY_ERROR,
  I18N_ENABLE_NAMESPACE_MUTATION_ERROR,
  I18N_ENABLED_NAMESPACE_QUERY_ERROR,
  DEFAULT_POLLING_INTERVAL,
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
} from 'ee/analytics/devops_reports/devops_adoption/constants';
import bulkEnableDevopsAdoptionNamespacesMutation from 'ee/analytics/devops_reports/devops_adoption/graphql/mutations/bulk_enable_devops_adoption_namespaces.mutation.graphql';
import devopsAdoptionEnabledNamespaces from 'ee/analytics/devops_reports/devops_adoption/graphql/queries/devops_adoption_enabled_namespaces.query.graphql';
import getGroupsQuery from 'ee/analytics/devops_reports/devops_adoption/graphql/queries/get_groups.query.graphql';
import { addEnabledNamespacesToCache } from 'ee/analytics/devops_reports/devops_adoption/utils/cache_updates';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking } from 'helpers/tracking_helper';
import DevopsScore from '~/analytics/devops_reports/components/devops_score.vue';
import API from '~/api';
import { groupNodes, devopsAdoptionNamespaceData } from '../mock_data';

jest.mock('ee/analytics/devops_reports/devops_adoption/utils/cache_updates', () => ({
  addEnabledNamespacesToCache: jest.fn(),
}));

Vue.use(VueApollo);

const NETWORK_ERROR = new Error('foo!');

const RESOURCE_TYPE_GROUP = 'groups';
const RESOURCE_TYPE_ENABLED_NAMESPACE = 'devopsAdoptionEnabledNamespaces';
const RESOURCE_TYPE_BULK_ENABLE_NAMESPACES = 'bulkEnableDevopsAdoptionNamespaces';

const STATE_EMPTY = 'empty';
const STATE_WITH_DATA = 'withData';
const STATE_NETWORK_ERROR = 'networkError';

const dataFactory = (resource) => {
  switch (resource) {
    case RESOURCE_TYPE_GROUP:
      return { nodes: groupNodes };
    case RESOURCE_TYPE_ENABLED_NAMESPACE:
      return devopsAdoptionNamespaceData;
    case RESOURCE_TYPE_BULK_ENABLE_NAMESPACES:
      return {
        enabledNamespaces: [devopsAdoptionNamespaceData.nodes[0]],
        errors: [],
      };
    default:
      return jest.fn();
  }
};

const promiseFactory = (state, resource) => {
  switch (state) {
    case STATE_EMPTY:
      return jest.fn().mockResolvedValue({
        data: { [resource]: { nodes: [] } },
      });
    case STATE_WITH_DATA:
      return jest.fn().mockResolvedValue({
        data: { [resource]: dataFactory(resource) },
      });
    case STATE_NETWORK_ERROR:
      return jest.fn().mockRejectedValue(NETWORK_ERROR);
    default:
      return jest.fn();
  }
};

describe('DevopsAdoptionApp', () => {
  let wrapper;

  const groupsEmpty = promiseFactory(STATE_EMPTY, RESOURCE_TYPE_GROUP);
  const enabledNamespacesEmpty = promiseFactory(STATE_EMPTY, RESOURCE_TYPE_ENABLED_NAMESPACE);
  const enableNamespacesMutationSpy = promiseFactory(
    STATE_WITH_DATA,
    RESOURCE_TYPE_BULK_ENABLE_NAMESPACES,
  );

  function createMockApolloProvider(options = {}) {
    const {
      groupsSpy = groupsEmpty,
      enabledNamespacesSpy = enabledNamespacesEmpty,
      enableNamespacesMutation = enableNamespacesMutationSpy,
    } = options;

    const mockApollo = createMockApollo(
      [
        [bulkEnableDevopsAdoptionNamespacesMutation, enableNamespacesMutation],
        [devopsAdoptionEnabledNamespaces, enabledNamespacesSpy],
      ],
      {
        Query: {
          groups: groupsSpy,
        },
      },
    );

    // Necessary for local resolvers to be activated
    mockApollo.defaultClient.cache.writeQuery({
      query: getGroupsQuery,
      data: {},
    });

    return mockApollo;
  }

  function createComponent(options = {}) {
    const { mockApollo, data = {}, provide = {} } = options;

    return shallowMountExtended(DevopsAdoptionApp, {
      apolloProvider: mockApollo,
      provide,
      data() {
        return data;
      },
      stubs: {
        GlTabs,
      },
    });
  }

  const findDevopsScoreTab = () => wrapper.findByTestId('devops-score-tab');
  const findOverviewTab = () => wrapper.findByTestId('devops-overview-tab');

  afterEach(() => {
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
  });

  describe('group data request', () => {
    let groupsSpy;

    afterEach(() => {
      groupsSpy = null;
    });

    describe('when group data is present', () => {
      beforeEach(async () => {
        groupsSpy = promiseFactory(STATE_WITH_DATA, RESOURCE_TYPE_GROUP);
        const mockApollo = createMockApolloProvider({ groupsSpy });
        wrapper = createComponent({ mockApollo });
        await waitForPromises();
      });

      it('should fetch data once', () => {
        expect(groupsSpy).toHaveBeenCalledTimes(1);
      });
    });

    describe('when error is thrown fetching group data', () => {
      beforeEach(async () => {
        jest.spyOn(Sentry, 'captureException');
        groupsSpy = promiseFactory(STATE_NETWORK_ERROR, RESOURCE_TYPE_GROUP);
        const mockApollo = createMockApolloProvider({ groupsSpy });
        wrapper = createComponent({ mockApollo });
        await waitForPromises();
      });

      it('should fetch data once', () => {
        expect(groupsSpy).toHaveBeenCalledTimes(1);
      });

      it('displays the error message and calls Sentry', () => {
        const alert = wrapper.findComponent(GlAlert);
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toBe(I18N_GROUPS_QUERY_ERROR);
        expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(NETWORK_ERROR);
      });
    });

    describe('refetches data when groupsSearchTerm is updated', () => {
      beforeEach(async () => {
        groupsSpy = promiseFactory(STATE_WITH_DATA, RESOURCE_TYPE_GROUP);
        const mockApollo = createMockApolloProvider({ groupsSpy });
        wrapper = createComponent({ mockApollo });
        await waitForPromises();
      });

      it.each`
        name                           | component
        ${'DevopsAdoptionSection'}     | ${DevopsAdoptionSection}
        ${'DevopsAdoptionAddDropdown'} | ${DevopsAdoptionAddDropdown}
      `('from $name', async ({ component }) => {
        expect(groupsSpy).toHaveBeenCalledTimes(1);

        wrapper.findComponent(component).vm.$emit('fetchGroups', 'group');

        await waitForPromises();

        expect(groupsSpy).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('enabled namespaces data', () => {
    describe('when there is no active group', () => {
      beforeEach(async () => {
        const mockApollo = createMockApolloProvider();
        wrapper = createComponent({ mockApollo });
        await waitForPromises();
      });

      it('does not attempt to enable a group', () => {
        expect(enableNamespacesMutationSpy).toHaveBeenCalledTimes(0);
      });
    });

    describe('when there is an active group', () => {
      const groupGid = devopsAdoptionNamespaceData.nodes[0].namespace.id;

      describe('which is enabled', () => {
        beforeEach(async () => {
          const mockApollo = createMockApolloProvider({
            enabledNamespacesSpy: promiseFactory(STATE_WITH_DATA, RESOURCE_TYPE_ENABLED_NAMESPACE),
          });
          const provide = {
            isGroup: true,
            groupGid,
          };
          wrapper = createComponent({ mockApollo, provide });
          await waitForPromises();
        });

        it('does not attempt to enable a group', () => {
          expect(enableNamespacesMutationSpy).toHaveBeenCalledTimes(0);
        });
      });

      describe('which is not enabled', () => {
        beforeEach(async () => {
          const mockApollo = createMockApolloProvider();
          const provide = {
            isGroup: true,
            groupGid,
          };
          wrapper = createComponent({ mockApollo, provide });
          await waitForPromises();
          await nextTick();
        });

        describe('enables the group', () => {
          it('makes a request with the correct variables', () => {
            expect(enableNamespacesMutationSpy).toHaveBeenCalledTimes(1);
            expect(enableNamespacesMutationSpy).toHaveBeenCalledWith({
              namespaceIds: [groupGid],
              displayNamespaceId: groupGid,
            });
          });

          it('calls addEnabledNamespacesToCache with the correct variables', () => {
            expect(addEnabledNamespacesToCache).toHaveBeenCalledTimes(1);
            expect(addEnabledNamespacesToCache).toHaveBeenCalledWith(
              expect.anything(),
              [devopsAdoptionNamespaceData.nodes[0]],
              {
                displayNamespaceId: groupGid,
              },
            );
          });

          describe('error handling', () => {
            beforeEach(async () => {
              jest.spyOn(Sentry, 'captureException');
              const provide = {
                isGroup: true,
                groupGid,
              };
              const mockApollo = createMockApolloProvider({
                enableNamespacesMutation: promiseFactory(
                  STATE_NETWORK_ERROR,
                  RESOURCE_TYPE_BULK_ENABLE_NAMESPACES,
                ),
              });
              wrapper = createComponent({ mockApollo, provide });
              await waitForPromises();
              await nextTick();
            });

            it('does not render the devops section', () => {
              expect(wrapper.findComponent(DevopsAdoptionSection).exists()).toBe(false);
            });

            it('displays the error message', () => {
              const alert = wrapper.findComponent(GlAlert);
              expect(alert.exists()).toBe(true);
              expect(alert.text()).toBe(I18N_ENABLE_NAMESPACE_MUTATION_ERROR);
            });

            it('calls Sentry', () => {
              expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(NETWORK_ERROR);
            });
          });
        });
      });
    });

    describe('when there is an error', () => {
      beforeEach(async () => {
        jest.spyOn(Sentry, 'captureException');
        const mockApollo = createMockApolloProvider({
          enabledNamespacesSpy: promiseFactory(
            STATE_NETWORK_ERROR,
            RESOURCE_TYPE_ENABLED_NAMESPACE,
          ),
        });
        wrapper = createComponent({ mockApollo });
        await waitForPromises();
      });

      it('does not render the devops section', () => {
        expect(wrapper.findComponent(DevopsAdoptionSection).exists()).toBe(false);
      });

      it('displays the error message', () => {
        const alert = wrapper.findComponent(GlAlert);
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toBe(I18N_ENABLED_NAMESPACE_QUERY_ERROR);
      });

      it('calls Sentry', () => {
        expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(NETWORK_ERROR);
      });
    });

    describe('data polling', () => {
      const mockIntervalId = 1234;

      beforeEach(async () => {
        jest.spyOn(window, 'setInterval').mockReturnValue(mockIntervalId);
        jest.spyOn(window, 'clearInterval').mockImplementation();

        wrapper = createComponent({
          mockApollo: createMockApolloProvider({
            groupsSpy: promiseFactory(STATE_WITH_DATA, RESOURCE_TYPE_ENABLED_NAMESPACE),
          }),
        });

        await waitForPromises();
      });

      it('sets pollTableData interval', () => {
        expect(window.setInterval).toHaveBeenCalledWith(
          wrapper.vm.pollTableData,
          DEFAULT_POLLING_INTERVAL,
        );
        expect(wrapper.vm.pollingTableData).toBe(mockIntervalId);
      });

      it('clears pollTableData interval when destroying', () => {
        wrapper.vm.$destroy();

        expect(window.clearInterval).toHaveBeenCalledWith(mockIntervalId);
      });
    });
  });

  describe('tabs', () => {
    const eventTrackingBehaviour = (testId, event) => {
      describe('event tracking', () => {
        it(`tracks the ${event} event when clicked`, () => {
          jest.spyOn(API, 'trackRedisHllUserEvent');
          const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          expect(API.trackRedisHllUserEvent).not.toHaveBeenCalled();

          wrapper.findByTestId(testId).vm.$emit('click');

          expect(API.trackRedisHllUserEvent).toHaveBeenCalledWith(event);
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_tab', {
            label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
            context: {
              schema: 'iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-0',
              data: {
                event_name: event,
                data_source: 'redis_hll',
              },
            },
          });
        });

        it('only tracks the event once', () => {
          jest.spyOn(API, 'trackRedisHllUserEvent');

          expect(API.trackRedisHllUserEvent).not.toHaveBeenCalled();

          const { vm } = wrapper.findByTestId(testId);
          vm.$emit('click');
          vm.$emit('click');

          expect(API.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
        });
      });
    };

    const defaultDevopsAdoptionTabBehavior = () => {
      describe('overview tab', () => {
        it('displays the overview tab', () => {
          expect(findOverviewTab().exists()).toBe(true);
        });

        it('displays the devops adoption overview component', () => {
          expect(findOverviewTab().findComponent(DevopsAdoptionOverview).exists()).toBe(true);
        });
      });

      describe('devops adoption tabs', () => {
        it('displays the configured number of tabs', () => {
          expect(wrapper.findAllByTestId('devops-adoption-tab')).toHaveLength(
            DEVOPS_ADOPTION_TABLE_CONFIGURATION.length,
          );
        });

        it('displays the devops section component with the tab', () => {
          expect(
            wrapper
              .findByTestId('devops-adoption-tab')
              .findComponent(DevopsAdoptionSection)
              .exists(),
          ).toBe(true);
        });

        it('displays the DevopsAdoptionAddDropdown as the last tab', () => {
          expect(wrapper.findComponent(DevopsAdoptionAddDropdown).exists()).toBe(true);
        });

        eventTrackingBehaviour('devops-adoption-tab', 'i_analytics_dev_ops_adoption');
      });
    };

    describe('admin level', () => {
      beforeEach(() => {
        const mockApollo = createMockApolloProvider();
        wrapper = createComponent({ mockApollo });
      });

      defaultDevopsAdoptionTabBehavior();

      describe('devops score tab', () => {
        it('displays the devops score tab', () => {
          expect(findDevopsScoreTab().exists()).toBe(true);
        });

        it('displays the devops score component', () => {
          expect(findDevopsScoreTab().findComponent(DevopsScore).exists()).toBe(true);
        });

        eventTrackingBehaviour('devops-score-tab', 'i_analytics_dev_ops_score');
      });
    });

    describe('group level', () => {
      beforeEach(() => {
        const mockApollo = createMockApolloProvider();
        wrapper = createComponent({
          mockApollo,
          provide: {
            isGroup: true,
            groupGid: devopsAdoptionNamespaceData.nodes[0].namespace.id,
          },
        });
      });

      defaultDevopsAdoptionTabBehavior();

      it('does not display the devops score tab', () => {
        expect(findDevopsScoreTab().exists()).toBe(false);
      });
    });
  });
});
