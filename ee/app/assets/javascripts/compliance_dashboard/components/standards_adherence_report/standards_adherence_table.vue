<script>
import { GlTable, GlIcon, GlLink, GlBadge } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { formatDate } from '~/lib/utils/datetime_utility';
import getProjectComplianceStandardsAdherence from '../../graphql/compliance_standards_adherence.query.graphql';
import {
  FAIL_STATUS,
  STANDARDS_ADHERENCE_CHECK_LABELS,
  STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS,
  STANDARDS_ADHERENCE_STANARD_LABELS,
  NO_STANDARDS_ADHERENCES_FOUND,
} from './constants';
// import FixSuggestionsSidebar from './fix_suggestions_sidebar.vue';

export default {
  name: 'ComplianceStandardsAdherenceTable',
  components: {
    GlTable,
    GlIcon,
    GlLink,
    GlBadge,
    // FixSuggestionsSidebar,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      queryError: false,
      adherences: {
        list: [],
      },
      showDrawer: false,
    };
  },
  apollo: {
    adherences: {
      query: getProjectComplianceStandardsAdherence,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        const { nodes } = data?.group?.projectComplianceStandardsAdherence || {};
        return {
          list: nodes,
        };
      },
      error(e) {
        Sentry.captureException(e);
        this.queryError = true;
      },
    },
  },
  methods: {
    adherenceCheckName(check) {
      return STANDARDS_ADHERENCE_CHECK_LABELS[check];
    },
    adherenceCheckDescription(check) {
      return STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS[check];
    },
    adherenceStandardLabel(standard) {
      return STANDARDS_ADHERENCE_STANARD_LABELS[standard];
    },
    closeDrawer() {
      this.showDrawer = false;
    },
    formatDate(dateString) {
      return formatDate(dateString, 'mmm d, yyyy');
    },
    isFailedStatus(status) {
      return status === FAIL_STATUS;
    },
  },
  fields: [
    {
      key: 'status',
      sortable: false,
      thClass: '',
      tdClass: '',
    },
    {
      key: 'project',
      sortable: false,
      thClass: '',
      tdClass: '',
    },
    {
      key: 'checks',
      sortable: false,
      thClass: '',
      tdClass: '',
    },
    {
      key: 'standard',
      sortable: false,
      thClass: '',
      tdClass: '',
    },
    {
      key: 'lastScanned',
      sortable: false,
      thClass: '',
      tdClass: '',
    },
    {
      key: 'fixSuggestions',
      sortable: false,
      thClass: '',
      tdClass: '',
    },
  ],
  noStandardsAdherencesFound: NO_STANDARDS_ADHERENCES_FOUND,
};
</script>

<template>
  <gl-table
    :fields="$options.fields"
    :items="adherences.list"
    :empty-text="$options.noStandardsAdherencesFound"
    show-empty
  >
    <template #cell(status)="{ item: { status } }">
      <span v-if="isFailedStatus(status)" class="gl-text-red-500">
        <gl-icon name="status_failed" /> {{ __('Fail') }}
      </span>
      <span v-else class="gl-text-green-500">
        <gl-icon name="status_success" /> {{ __('Success') }}
      </span>
    </template>

    <template #cell(project)="{ item: { project } }">
      <div>{{ project.name }}</div>
      <div v-for="framework in project.complianceFrameworks.nodes" :key="framework.id">
        <gl-badge size="sm" class="gl-mt-3"> {{ framework.name }}</gl-badge>
      </div>
    </template>

    <template #cell(checks)="{ item: { checkName } }">
      <div class="gl-font-weight-bold">{{ adherenceCheckName(checkName) }}</div>
      <div class="gl-mt-2">{{ adherenceCheckDescription(checkName) }}</div>
    </template>

    <template #cell(standard)="{ item: { standard } }">
      {{ adherenceStandardLabel(standard) }}
    </template>

    <template #cell(lastScanned)="{ item: { updatedAt } }">
      {{ formatDate(updatedAt) }}
    </template>

    <!-- Note: This template will be replaced with the template below -->
    <!-- as this is part of https://gitlab.com/gitlab-org/gitlab/-/issues/413718 -->
    <template #cell(fixSuggestions)="{}">
      <gl-link @click="showDrawer = true">{{
        s__('ComplianceStandardsAdherence|View details')
      }}</gl-link>
    </template>

    <!--      <template #cell(fixSuggestions)="{ item: { status, project, checks, fixSuggestions } }">-->
    <!--        <gl-link @click="showDrawer = true">{{ fixSuggestions }}</gl-link>-->

    <!--        <fix-suggestions-sidebar-->
    <!--          :status="status"-->
    <!--          :project="project"-->
    <!--          :title="checks.name"-->
    <!--          :description="checks.description"-->
    <!--          :show-drawer="showDrawer"-->
    <!--          @close="closeDrawer"-->
    <!--        />-->
    <!--      </template>-->
  </gl-table>
</template>
