import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import EnvironmentAlert from 'ee/environments/components/environment_alert.vue';
import EnvironmentTable from '~/environments/components/environments_table.vue';

describe('Environment table', () => {
  let wrapper;

  const factory = async (options = {}, m = mount) => {
    wrapper = m(EnvironmentTable, {
      ...options,
    });
    await nextTick();
    await jest.runOnlyPendingTimers();
  };

  it('should render the alert if there is one', async () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      hasDeployBoard: false,
      has_opened_alert: true,
    };

    await factory(
      {
        propsData: {
          environments: [mockItem],
          userCalloutsPath: '/callouts',
          lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
          helpCanaryDeploymentsPath: 'help/canary-deployments',
        },
      },
      shallowMount,
    );

    expect(wrapper.findComponent(EnvironmentAlert).exists()).toBe(true);
  });
});
