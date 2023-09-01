import AdminRunnersDashboardApp from 'ee/ci/runner/admin_runners_dashboard/admin_runners_dashboard_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerActiveList from 'ee/ci/runner/components/runner_active_list.vue';
import RunnerJobFailures from 'ee/ci/runner/components/runner_job_failures.vue';
import RunnerWaitTimes from 'ee/ci/runner/components/runner_wait_times.vue';

describe('AdminRunnersDashboardApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminRunnersDashboardApp);
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows dashboard panels', () => {
    expect(wrapper.findComponent(RunnerActiveList).exists()).toBe(true);
    expect(wrapper.findComponent(RunnerJobFailures).exists()).toBe(true);
    expect(wrapper.findComponent(RunnerWaitTimes).exists()).toBe(true);
  });
});
