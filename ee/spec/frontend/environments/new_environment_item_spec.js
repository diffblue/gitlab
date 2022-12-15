import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubTransition } from 'helpers/stub_transition';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import EnvironmentAlert from 'ee/environments/components/environment_alert.vue';
import EnvironmentApproval from 'ee/environments/components/environment_approval.vue';
import alertQuery from 'ee/environments/graphql/queries/environment.query.graphql';
import { resolvedEnvironment } from 'jest/environments/graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/new_environment_item.vue', () => {
  let wrapper;
  let alert;
  let approval;

  const createApolloProvider = () => {
    return createMockApollo([
      [
        alertQuery,
        jest.fn().mockResolvedValue({
          data: {
            project: {
              id: '1',
              environment: {
                id: '2',
                latestOpenedMostSevereAlert: {
                  id: '4',
                  severity: 'CRITICAL',
                  title: 'alert title',
                  prometheusAlert: { id: '3', humanizedText: '>0.1% jest' },
                  detailsUrl: '/alert/details',
                  startedAt: new Date(),
                },
              },
            },
          },
        }),
      ],
    ]);
  };

  const createWrapper = async ({ propsData = {}, apolloProvider } = {}) => {
    wrapper = mountExtended(EnvironmentItem, {
      apolloProvider,
      propsData: { environment: resolvedEnvironment, ...propsData },
      provide: { helpPagePath: '/help', projectId: '1', projectPath: '/1' },
      stubs: { transition: stubTransition() },
    });

    await nextTick();

    alert = wrapper.findComponent(EnvironmentAlert);
    approval = wrapper.findComponent(EnvironmentApproval);
  };

  it('shows an alert if one is opened', async () => {
    const environment = { ...resolvedEnvironment, hasOpenedAlert: true };
    await createWrapper({ propsData: { environment }, apolloProvider: createApolloProvider() });

    expect(alert.exists()).toBe(true);
    expect(alert.props('environment')).toBe(environment);
  });

  it('does not show an alert if one is opened', async () => {
    await createWrapper({ apolloProvider: createApolloProvider() });

    expect(alert.exists()).toBe(false);
  });

  it('emits a change if approval changes', async () => {
    const upcomingDeployment = resolvedEnvironment.lastDeployment;
    const environment = { ...resolvedEnvironment, lastDeployment: null, upcomingDeployment };
    await createWrapper({ propsData: { environment }, apolloProvider: createApolloProvider() });

    approval.vm.$emit('change');

    expect(wrapper.emitted('change')).toEqual([[]]);
  });
});
