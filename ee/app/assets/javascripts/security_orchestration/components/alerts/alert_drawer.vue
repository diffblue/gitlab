<script>
import { GlAlert, GlButton, GlDrawer, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import getAlertDetailsQuery from '~/graphql_shared/queries/alert_details.query.graphql';
import { capitalizeFirstCharacter, splitCamelCase } from '~/lib/utils/text_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarStatus from '~/vue_shared/alert_details/components/sidebar/sidebar_status.vue';
import createIssueMutation from '~/vue_shared/alert_details/graphql/mutations/alert_issue_create.mutation.graphql';
import { getContentWrapperHeight } from '../../utils';
import { ALERT_DETAILS_LOADING_ROWS, DRAWER_ERRORS, HIDDEN_VALUES } from './constants';

export default {
  ALERT_DETAILS_LOADING_ROWS,
  i18n: {
    CREATE_ISSUE: __('Create incident'),
    ERRORS: { ...DRAWER_ERRORS },
  },
  components: {
    SidebarStatus,
    GlAlert,
    GlButton,
    GlDrawer,
    GlLink,
    GlSkeletonLoader,
    SidebarAssigneesWidget,
  },
  provide: { canUpdate: true },
  inject: ['projectPath'],
  apollo: {
    alertDetails: {
      query: getAlertDetailsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          alertId: this.selectedAlert.iid,
        };
      },
      update(data) {
        return data?.project?.alertManagementAlerts?.nodes?.[0] ?? null;
      },
      error(error) {
        this.handleAlertError({ type: 'DETAILS', error });
      },
    },
  },
  props: {
    isAlertDrawerOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    selectedAlert: {
      type: Object,
      required: true,
      validator: (value) => ['iid', 'title'].every((prop) => value[prop]),
    },
  },
  data() {
    return {
      alertDetails: {},
      errorMessage: '',
      creatingIssue: false,
    };
  },
  computed: {
    alertIssuePath() {
      return this.selectedAlert.issue?.webUrl || '';
    },
    curatedAlertDetails() {
      return Object.entries({ ...this.alertDetails, ...this.alertDetails?.details }).reduce(
        (acc, [key, value]) => {
          return HIDDEN_VALUES.includes(key) || !value ? acc : [...acc, [key, value]];
        },
        [],
      );
    },
    errored() {
      return Boolean(this.errorMessage);
    },
    hasIssue() {
      return Boolean(this.selectedAlert.issue);
    },
    issueText() {
      return `#${this.selectedAlert.issue?.iid}`;
    },
    isLoadingDetails() {
      return this.$apollo.queries.alertDetails.loading;
    },
  },
  methods: {
    async createIssue() {
      this.creatingIssue = true;

      try {
        const response = await this.$apollo.mutate({
          mutation: createIssueMutation,
          variables: {
            iid: this.selectedAlert.iid,
            projectPath: this.projectPath,
          },
        });

        const { errors, issue } = response.data.createAlertIssue;
        if (errors?.length) {
          throw new Error(errors[0]);
        }
        visitUrl(issue.webUrl);
      } catch (error) {
        this.handleAlertError({ type: 'CREATE_ISSUE', error });
        this.creatingIssue = false;
      }
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight('.js-threat-monitoring-container-wrapper');
    },
    handleAlertUpdate() {
      this.$emit('alert-update');
    },
    handleAlertError({ type, error }) {
      this.errorMessage = this.$options.i18n.ERRORS[type];
      Sentry.captureException(error);
    },
    humanizeText(text) {
      return capitalizeFirstCharacter(splitCamelCase(text));
    },
  },
};
</script>
<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight()"
    :z-index="252"
    class="threat-monitoring-alert-drawer gl-bg-gray-10"
    :open="isAlertDrawerOpen"
    @close="$emit('deselect-alert')"
  >
    <template #title>
      <h5 class="gl-my-0">{{ selectedAlert.title }}</h5>
    </template>
    <template #header>
      <div class="gl-mt-5">
        <gl-link v-if="hasIssue" :href="alertIssuePath" data-testid="issue-link">
          {{ issueText }}
        </gl-link>
        <gl-button
          v-else
          category="primary"
          variant="confirm"
          :loading="creatingIssue"
          data-testid="create-issue-button"
          @click="createIssue"
        >
          {{ $options.i18n.CREATE_ISSUE }}
        </gl-button>
      </div>
    </template>
    <div v-if="errored" class="gl-p-0!">
      <gl-alert variant="danger" :dismissible="false">
        {{ errorMessage }}
      </gl-alert>
    </div>
    <sidebar-assignees-widget
      issuable-type="alert"
      :iid="selectedAlert.iid"
      :full-path="projectPath"
      :allow-multiple-assignees="false"
      @assignees-updated="handleAlertUpdate"
    />
    <sidebar-status
      :alert="selectedAlert"
      :project-path="projectPath"
      text-class="gl-font-weight-bold"
      @alert-update="handleAlertUpdate"
    />
    <div v-if="isLoadingDetails">
      <div v-for="row in $options.ALERT_DETAILS_LOADING_ROWS" :key="row" class="gl-mb-5">
        <gl-skeleton-loader :lines="2" :width="400" />
      </div>
    </div>
    <div v-else data-testid="details-list">
      <div v-for="[key, value] in curatedAlertDetails" :key="key" class="gl-mb-5">
        <div class="gl-mb-2">{{ humanizeText(key) }}</div>
        <b>{{ value }}</b>
      </div>
    </div>
  </gl-drawer>
</template>
