<script>
import * as Sentry from '@sentry/browser';

import { __, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import * as StatusCheckRetryApi from 'ee/api/status_check_api';
import Poll from '~/lib/utils/poll';
import { responseHasPendingChecks } from 'ee/vue_merge_request_widget/extensions/status_checks/utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

import { getFailedChecksWithLoadingState, mapStatusCheckResponse } from './mappers';

export default {
  name: 'WidgetStatusChecks',
  components: {
    MrWidget,
  },
  i18n: {
    label: s__('StatusCheck|status checks'),
    loading: s__('StatusCheck|Status checks are being fetched'),
    error: s__('StatusCheck|Failed to load status checks'),
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      collapsedError: null,
      collapsedData: {},
      loadingState: undefined,
      hasError: false,
      poll: null,
    };
  },
  computed: {
    summary() {
      const { approved = [], pending = [], failed = [] } = this.collapsedData;

      if (approved.length > 0 && failed.length === 0 && pending.length === 0) {
        return { title: s__('StatusCheck|Status checks all passed') };
      }

      const reports = [];

      if (failed.length > 0) {
        reports.push(
          `%{danger_start}${sprintf(s__('StatusCheck|%{failed} failed'), {
            failed: failed.length,
          })}%{danger_end}`,
        );
      }
      if (pending.length > 0) {
        reports.push(
          `%{same_start}${sprintf(s__('StatusCheck|%{pending} pending'), {
            pending: pending.length,
          })}%{same_end}`,
        );
      }

      return {
        title: s__('StatusCheck|Status checks'),
        subtitle: reports.join(__(', ')),
      };
    },
    apiStatusChecksPath() {
      return this.mr.apiStatusChecksPath;
    },
    statusIcon() {
      const { pending = [], failed = [] } = this.collapsedData;

      if (failed.length > 0) {
        return EXTENSION_ICONS.warning;
      }

      if (pending.length > 0) {
        return EXTENSION_ICONS.neutral;
      }

      return EXTENSION_ICONS.success;
    },
    tertiaryButtons() {
      const actionButtons = [];

      if (this.hasError) {
        const isLoading = Boolean(this.loadingState);

        actionButtons.push({
          text: __('Retry'),
          onClick: () => this.fetchStatusChecks(),
          loading: isLoading,
          disabled: isLoading,
        });
      }

      return actionButtons;
    },
    expandedData() {
      const { approved = [], pending = [], failed = [] } = this.collapsedData;
      return [...approved, ...pending, ...failed];
    },
  },
  mounted() {
    this.startPolling();
  },
  beforeDestroy() {
    this.stopPolling();
  },
  methods: {
    fetchStatusChecks() {
      if (Object.keys(this.collapsedData).length > 0) {
        this.loadingState = MrWidget.LOADING_STATE_STATUS_ICON;
      } else {
        this.loadingState = MrWidget.LOADING_STATE_COLLAPSED;
      }

      return axios.get(this.apiStatusChecksPath);
    },
    async retryStatusCheck(statusCheck) {
      const { failed } = this.collapsedData;
      const failedChecksWithLoading = getFailedChecksWithLoadingState(failed, statusCheck.id);
      this.collapsedData.failed = failedChecksWithLoading;
      this.loadingState = MrWidget.LOADING_STATE_STATUS_ICON;

      try {
        await StatusCheckRetryApi.mrStatusCheckRetry({
          projectId: this.mr.targetProjectId,
          mergeRequestId: this.mr.iid,
          externalStatusCheckId: statusCheck.id,
        });
      } catch (err) {
        if (err?.response?.status === HTTP_STATUS_UNPROCESSABLE_ENTITY) {
          this.collapsedData = await this.fetchStatusChecks();
          return;
        }

        Sentry.captureException(err);
      }
    },
    startPolling() {
      this.poll = new Poll({
        resource: {
          fetchData: () => this.fetchStatusChecks(),
        },
        method: 'fetchData',
        successCallback: (response) => {
          this.loadingState = undefined;

          if (!responseHasPendingChecks(response)) {
            this.stopPolling();
          }

          this.collapsedData = mapStatusCheckResponse(
            response,
            {
              canRetry: this.mr.canRetryExternalStatusChecks,
            },
            (statusCheck) => this.retryStatusCheck(statusCheck),
          );
        },
        errorCallback: (e) => {
          this.loadingState = undefined;
          this.setCollapsedError(e);
        },
      });

      this.poll.makeDelayedRequest(1);
    },
    stopPolling() {
      this.poll?.stop();
      this.poll = null;
    },
    setCollapsedError(err) {
      this.hasError = true;
      Sentry.captureException(err);
    },
  },
  helpPopover: {
    options: {
      title: s__('StatusCheck|What is status check?'),
    },
    content: {
      text: s__(
        'StatusCheck|Status checks are API calls to external systems that request the status of an external requirement.',
      ),
      learnMorePath: helpPagePath('user/project/merge_requests/status_checks'),
    },
  },
};
</script>

<template>
  <mr-widget
    :error-text="$options.i18n.error"
    :has-error="hasError"
    :status-icon-name="statusIcon"
    :loading-text="$options.i18n.loading"
    :loading-state="loadingState"
    :action-buttons="tertiaryButtons"
    :help-popover="$options.helpPopover"
    :widget-name="$options.name"
    :summary="summary"
    :content="expandedData"
    data-testid="info-status-checks"
    is-collapsible
  />
</template>
