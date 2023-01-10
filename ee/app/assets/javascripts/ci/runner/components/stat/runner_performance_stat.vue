<script>
import { GlLink, GlIcon, GlModalDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RunnerPerformanceModal from './runner_performance_modal.vue';

export default {
  components: {
    GlLink,
    GlIcon,
    RunnerPerformanceModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    shouldShowPerformanceStat() {
      return this.glFeatures?.runnerPerformanceInsights;
    },
  },
  MODAL_ID: 'runner-performance-modal',
};
</script>
<template>
  <div v-if="shouldShowPerformanceStat" class="gl-line-height-normal gl-p-2">
    <div class="gl-mb-4">
      <span class="gl-text-gray-700">{{ s__('Runners|Runners performance') }}</span>
    </div>
    <div>
      <gl-link v-gl-modal="$options.MODAL_ID" class="gl-text-body!">
        {{ s__('Runners|View metrics') }} <gl-icon name="chart" />
      </gl-link>
      <runner-performance-modal :modal-id="$options.MODAL_ID" />
    </div>
  </div>
</template>
