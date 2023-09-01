<script>
import RunnerJobFailures from '../components/runner_job_failures.vue';
import RunnerActiveList from '../components/runner_active_list.vue';
import RunnerWaitTimes from '../components/runner_wait_times.vue';

export default {
  components: {
    RunnerJobFailures,
    RunnerActiveList,
    RunnerWaitTimes,
  },
};
</script>
<template>
  <div>
    <h1 class="gl-font-size-h1">{{ s__('Runners|Fleet dashboard') }}</h1>
    <p>
      {{ s__('Runners|Use the dashboard to view performance statistics of your runner fleet.') }}
    </p>

    <div class="gl-md-display-flex gl-gap-3">
      <runner-job-failures class="gl-flex-grow-2 gl-flex-basis-0 gl-mb-3" />
      <runner-active-list class="gl-flex-grow-1 gl-flex-basis-0 gl-mb-3" />
    </div>
    <div class="gl-md-display-flex">
      <runner-wait-times class="gl-flex-grow-1 gl-flex-basis-0 gl-mb-3" />
    </div>
  </div>
</template>
