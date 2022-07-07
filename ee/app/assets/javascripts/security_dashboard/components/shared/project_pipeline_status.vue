<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import projectAutoFixMrsCountQuery from 'ee/security_dashboard/graphql/queries/project_auto_fix_mrs_count.query.graphql';
import { __, s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PipelineStatusBadge from './pipeline_status_badge.vue';

export default {
  components: {
    GlLink,
    GlIcon,
    TimeAgoTooltip,
    PipelineStatusBadge,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectFullPath', 'autoFixMrsPath'],
  apollo: {
    autoFixMrsCount: {
      query: projectAutoFixMrsCountQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
        };
      },
      update(data) {
        return data?.project?.mergeRequests?.count || 0;
      },
      skip() {
        return !this.glFeatures.securityAutoFix;
      },
    },
  },
  props: {
    pipeline: { type: Object, required: true },
  },
  computed: {
    parsingStatusMessage() {
      const { hasParsingErrors, hasParsingWarnings } = this.pipeline;

      if (hasParsingErrors && hasParsingWarnings) {
        return this.$options.i18n.hasParsingErrorsAndWarnings;
      }
      if (hasParsingErrors) {
        return this.$options.i18n.hasParsingErrors;
      }
      if (hasParsingWarnings) {
        return this.$options.i18n.hasParsingWarnings;
      }

      return '';
    },
  },
  i18n: {
    lastUpdated: __('Last updated'),
    hasParsingErrorsAndWarnings: s__('SecurityReports|Parsing errors and warnings in pipeline'),
    hasParsingErrors: s__('SecurityReports|Parsing errors in pipeline'),
    hasParsingWarnings: s__('SecurityReports|Parsing warnings in pipeline'),
    autoFixSolutions: s__('AutoRemediation|Auto-fix solutions'),
    autoFixMrsLink: s__('AutoRemediation|%{mrsCount} ready for review'),
  },
};
</script>

<template>
  <div
    class="gl-md-display-flex gl-align-items-center gl-border-solid gl-border-1 gl-border-gray-100 gl-p-6"
  >
    <div class="gl-mr-3">
      <span class="gl-font-weight-bold gl-mr-3">{{ $options.i18n.lastUpdated }}</span
      ><span class="gl-white-space-nowrap">
        <time-ago-tooltip class="gl-pr-3" :time="pipeline.createdAt" /><gl-link
          :href="pipeline.path"
          >#{{ pipeline.id }}</gl-link
        >
        <pipeline-status-badge :pipeline="pipeline" class="gl-ml-3" />
      </span>
    </div>
    <div
      v-if="parsingStatusMessage"
      class="gl-mr-3 gl-mt-5 gl-md-mt-0 gl-text-orange-400 gl-font-weight-bold"
      data-testid="parsing-status-notice"
    >
      <gl-icon name="warning" class="gl-mr-3" />{{ parsingStatusMessage }}
    </div>
    <div
      v-if="autoFixMrsCount"
      class="gl-md-ml-3 gl-mt-5 gl-md-mt-0"
      data-testid="auto-fix-mrs-link"
    >
      <span class="gl-font-weight-bold gl-mr-3">{{ $options.i18n.autoFixSolutions }}</span>
      <gl-link :href="autoFixMrsPath" class="gl-white-space-nowrap">{{
        sprintf($options.i18n.autoFixMrsLink, { mrsCount: autoFixMrsCount })
      }}</gl-link>
    </div>
  </div>
</template>
