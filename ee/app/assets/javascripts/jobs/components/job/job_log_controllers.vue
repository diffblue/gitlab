<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';
import JobLogController from '~/jobs/components/job/job_log_controllers.vue';
import RootCauseAnalysis from './root_cause_analysis.vue';

export default {
  components: {
    JobLogController,
    GlButton,
    RootCauseAnalysis,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['aiRootCauseAnalysisAvailable'],
  props: {
    size: {
      type: Number,
      required: true,
    },
    rawPath: {
      type: String,
      required: false,
      default: null,
    },
    isScrollTopDisabled: {
      type: Boolean,
      required: true,
    },
    isScrollBottomDisabled: {
      type: Boolean,
      required: true,
    },
    isScrollingDown: {
      type: Boolean,
      required: true,
    },
    isJobLogSizeVisible: {
      type: Boolean,
      required: true,
    },
    isComplete: {
      type: Boolean,
      required: true,
    },
    jobLog: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isRootCauseDrawerShown: false,
    };
  },
  computed: {
    rootCauseAnalysisIsAvailable() {
      return this.glFeatures.aiBuildFailureCause && this.aiRootCauseAnalysisAvailable;
    },
    jobId() {
      return convertToGraphQLId(TYPENAME_CI_BUILD, this.job.id);
    },
    ...mapState(['job', 'isLoading']),
  },
  methods: {
    toggleDrawer() {
      this.isRootCauseDrawerShown = !this.isRootCauseDrawerShown;
    },
    handleScrollTop() {
      this.$emit('scrollJobLogTop');
    },
    handleScrollBottom() {
      this.$emit('scrollJobLogBottom');
    },
    handleSearchResults(searchResults) {
      this.$emit('searchResults', searchResults);
    },
  },
  i18n: {
    buttonName: s__('Jobs|Root cause analysis'),
  },
};
</script>
<template>
  <div class="gl-display-contents">
    <root-cause-analysis
      v-if="rootCauseAnalysisIsAvailable"
      :is-shown="isRootCauseDrawerShown"
      :job-id="jobId || ''"
      :is-job-loading="isLoading"
      @close="toggleDrawer"
    />
    <job-log-controller
      :size="size"
      :raw-path="rawPath"
      :is-scroll-top-disabled="isScrollTopDisabled"
      :is-scroll-bottom-disabled="isScrollBottomDisabled"
      :is-scrolling-down="isScrollingDown"
      :is-job-log-size-visible="isJobLogSizeVisible"
      :is-complete="isComplete"
      :job-log="jobLog"
      @scrollJobLogTop="handleScrollTop"
      @scrollJobLogBottom="handleScrollBottom"
      @searchResults="handleSearchResults"
    >
      <template #controllers>
        <gl-button v-if="rootCauseAnalysisIsAvailable" class="gl-mr-2" @click="toggleDrawer">{{
          $options.i18n.buttonName
        }}</gl-button>
      </template>
    </job-log-controller>
  </div>
</template>
