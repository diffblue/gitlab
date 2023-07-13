<script>
import RunnerActiveList from '../components/runner_active_list.vue';

export default {
  components: {
    RunnerActiveList,
  },
};
</script>
<template>
  <div>
    <h1 class="gl-font-size-h1">{{ s__('Runners|Fleet dashboard') }}</h1>

    <runner-active-list />
  </div>
</template>
