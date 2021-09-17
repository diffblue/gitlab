<script>
import { GlButton } from '@gitlab/ui';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

export default {
  name: 'MrWidgetEnableFeaturePrompt',
  components: {
    CiIcon,
    GitlabExperiment,
    GlButton,
  },
  props: {
    feature: {
      type: String,
      required: true,
    },
  },
  data() {
    const dismissalKey = [this.$options.name, this.feature, 'dismissed'].join('.');
    return {
      dismissalKey,
      status: {
        group: 'notification',
        icon: 'status-neutral',
      },
      dismissed: localStorage.getItem(dismissalKey),
    };
  },
  methods: {
    dismiss() {
      localStorage.setItem(this.dismissalKey, (this.dismissed = true));
    },
  },
};
</script>
<template>
  <gitlab-experiment v-if="!dismissed" :name="feature">
    <template #control></template>
    <template #candidate>
      <div class="mr-widget-body media">
        <ci-icon class="gl-mr-3" :status="status" :size="24" />
        <div class="media-body gl-text-gray-400">
          <slot></slot>
        </div>
        <gl-button
          category="tertiary"
          size="small"
          icon="close"
          :aria-label="s__('mrWidget|Dismiss')"
          data-track-action="dismissed"
          :data-track-experiment="feature"
          @click="dismiss"
        />
      </div>
    </template>
  </gitlab-experiment>
</template>
