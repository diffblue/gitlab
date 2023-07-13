import AdminRunnersDashboardApp from 'ee/ci/runner/admin_runners_dashboard/admin_runners_dashboard_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerActiveList from 'ee/ci/runner/components/runner_active_list.vue';

describe('AdminRunnersDashboardApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminRunnersDashboardApp);
  };

  it('shows active runners list', () => {
    createComponent();

    expect(wrapper.findComponent(RunnerActiveList).exists()).toBe(true);
  });
});
