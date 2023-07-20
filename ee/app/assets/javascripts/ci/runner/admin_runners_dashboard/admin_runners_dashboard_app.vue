<script>
import RunnerActiveList from '../components/runner_active_list.vue';
import RunnerWaitTimes from '../components/runner_wait_times.vue';

export default {
  components: {
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
      <runner-wait-times class="gl-flex-grow-1 gl-flex-basis-0 gl-mb-3" />
      <runner-active-list class="gl-flex-grow-1 gl-flex-basis-0 gl-mb-3" />
    </div>
  </div>
</template>
