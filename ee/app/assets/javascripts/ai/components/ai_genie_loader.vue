<script>
import { GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { i18n, GENIE_CHAT_LOADING_TRANSITION_DURATION } from '../constants';

export default {
  name: 'AiGenieLoader',
  components: {
    GlSprintf,
  },
  i18n,
  data() {
    return {
      loadingSequence: 0,
      timeout: null,
    };
  },
  computed: {
    ...mapState(['toolMessage']),
  },
  beforeDestroy() {
    clearTimeout(this.timeout);
  },
  mounted() {
    this.computeTransitionWidth();
    this.enter();
  },
  methods: {
    computeTransitionWidth() {
      const container = this.$refs.transition;
      const active = this.$refs.currentTransition[0]; // refs in v-for loops are always Arrays
      const { width, height } = active.getBoundingClientRect();
      container.$el.style.width = `${width}px`;
      container.$el.style.height = `${height}px`;
    },
    enter() {
      this.timeout = setTimeout(() => {
        if (this.loadingSequence === 3) {
          this.loadingSequence = 0;
        } else {
          this.loadingSequence += 1;
        }
        this.enter();
      }, GENIE_CHAT_LOADING_TRANSITION_DURATION);
    },
  },
};
</script>

<template>
  <div class="ai-genie-loader">
    <div
      class="gl-py-3 gl-px-4 gl-mb-4 gl-rounded-lg gl-rounded-bottom-left-none gl-display-flex gl-text-gray-500"
    >
      <div class="gl-display-flex gl-align-items-center gl-mr-3">
        <div class="ai-genie-loader__dot ai-genie-loader__dot--1"></div>
        <div class="ai-genie-loader__dot ai-genie-loader__dot--2"></div>
        <div class="ai-genie-loader__dot ai-genie-loader__dot--3"></div>
      </div>
      <gl-sprintf :message="$options.i18n.GENIE_CHAT_LOADING_MESSAGE">
        <template #tool>
          <strong class="gl-mr-2" data-testid="tool">
            <span v-if="toolMessage">{{ toolMessage.content }}</span>
            <span v-else>{{ $options.i18n.GITLAB_DUO }}</span>
          </strong>
        </template>
        <template #transition>
          <transition-group
            ref="transition"
            name="text"
            class="transition gl-display-inline-block gl-mx-2"
            @after-leave="computeTransitionWidth"
          >
            <span
              v-for="(message, index) in $options.i18n.GENIE_CHAT_LOADING_TRANSITIONS"
              v-show="index === loadingSequence"
              :ref="index === loadingSequence && 'currentTransition'"
              :key="`message-${index}`"
              class="gl-white-space-nowrap"
              >{{ message }}</span
            >
          </transition-group>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
