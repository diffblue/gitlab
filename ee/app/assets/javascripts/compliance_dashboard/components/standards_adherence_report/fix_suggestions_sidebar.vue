<script>
import { GlDrawer, GlIcon, GlBadge, GlButton, GlLink } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  FAIL_STATUS,
  STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS,
  STANDARDS_ADHERENCE_CHECK_FAILURE_REASONS,
  STANDARDS_ADHERENCE_CHECK_SUCCESS_REASONS,
  STANDARDS_ADHERENCE_CHECK_MR_FIX_TITLE,
  STANDARDS_ADHERENCE_CHECK_MR_FIX_FEATURES,
  STANDARDS_ADHERENCE_CHECK_LABELS,
  STANDARDS_ADHERENCE_CHECK_MR_FIX_LEARN_MORE_DOCS_LINKS,
} from './constants';

export default {
  name: 'FixSuggestionsSidebar',
  components: {
    GlDrawer,
    GlIcon,
    GlBadge,
    GlButton,
    GlLink,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    showDrawer: {
      type: Boolean,
      required: false,
      default: false,
    },
    adherence: {
      type: Object,
      required: true,
    },
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    project() {
      return this.adherence.project;
    },
    projectMRSettingsPath() {
      return joinPaths(this.project.webUrl, '-', 'settings', 'merge_requests');
    },
    isFailedStatus() {
      return this.adherence.status === FAIL_STATUS;
    },
    adherenceCheckName() {
      return STANDARDS_ADHERENCE_CHECK_LABELS[this.adherence.checkName];
    },
    adherenceCheckDescription() {
      return STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS[this.adherence.checkName];
    },
    adherenceCheckFailureReason() {
      return STANDARDS_ADHERENCE_CHECK_FAILURE_REASONS[this.adherence.checkName];
    },
    adherenceCheckSuccessReason() {
      return STANDARDS_ADHERENCE_CHECK_SUCCESS_REASONS[this.adherence.checkName];
    },
    adherenceCheckLearnMoreLink() {
      return STANDARDS_ADHERENCE_CHECK_MR_FIX_LEARN_MORE_DOCS_LINKS[this.adherence.checkName];
    },
  },
  standardsAdherenceCheckMRFixTitle: STANDARDS_ADHERENCE_CHECK_MR_FIX_TITLE,
  standardsAdherenceCheckMRFixes: STANDARDS_ADHERENCE_CHECK_MR_FIX_FEATURES,
  projectMRSettingsDocsPath: helpPagePath('user/project/merge_requests/approvals/rules'),
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="showDrawer"
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template #title>
      <div>
        <h2 class="gl-mt-0" data-testid="sidebar-title">{{ adherenceCheckName }}</h2>
        <div>
          <span v-if="isFailedStatus" class="gl-text-red-500 gl-font-weight-bold">
            <gl-icon name="status_failed" /> {{ __('Fail') }}
          </span>
          <span v-else class="gl-text-green-500 gl-font-weight-bold">
            <gl-icon name="status_success" /> {{ __('Success') }}
          </span>

          <gl-link class="gl-mx-3" :href="project.webUrl"> {{ project.name }} </gl-link>

          <span v-for="framework in project.complianceFrameworks.nodes" :key="framework.id">
            <gl-badge size="sm" class="gl-mt-3"> {{ framework.name }}</gl-badge>
          </span>
        </div>
      </div>
    </template>

    <template #default>
      <div>
        <h4 data-testid="sidebar-requirement-title" class="gl-mt-0">
          {{ s__('ComplianceStandardsAdherence|Requirement') }}
        </h4>
        <span data-testid="sidebar-requirement-content">{{ adherenceCheckDescription }}</span>
      </div>

      <div v-if="isFailedStatus">
        <h4 data-testid="sidebar-failure-title" class="gl-mt-0">
          {{ s__('ComplianceStandardsAdherence|Failure reason') }}
        </h4>
        <span data-testid="sidebar-failure-content">{{ adherenceCheckFailureReason }}</span>
      </div>
      <div v-else>
        <h4 data-testid="sidebar-success-title" class="gl-mt-0">
          {{ s__('ComplianceStandardsAdherence|Success reason') }}
        </h4>
        <span data-testid="sidebar-success-content">{{ adherenceCheckSuccessReason }}</span>
      </div>

      <div v-if="isFailedStatus" data-testid="sidebar-how-to-fix">
        <div>
          <h4 class="gl-mt-0">{{ s__('ComplianceStandardsAdherence|How to fix') }}</h4>
        </div>
        <div class="gl-my-5">
          {{ $options.standardsAdherenceCheckMRFixTitle }}
        </div>
        <div
          v-for="fix in $options.standardsAdherenceCheckMRFixes"
          :key="fix.title"
          class="gl-mb-4"
        >
          <div class="gl-my-2 gl-font-weight-bold">{{ fix.title }}</div>
          <div class="gl-mb-4">{{ fix.description }}</div>
          <gl-button
            class="gl-my-3"
            size="small"
            category="secondary"
            variant="confirm"
            :href="projectMRSettingsPath"
            data-testid="sidebar-mr-settings-button"
          >
            {{ __('Manage rules') }}
          </gl-button>
          <gl-button
            size="small"
            :href="adherenceCheckLearnMoreLink"
            data-testid="sidebar-mr-settings-learn-more-button"
          >
            {{ __('Learn more') }}
          </gl-button>
        </div>
      </div>
    </template>
  </gl-drawer>
</template>
