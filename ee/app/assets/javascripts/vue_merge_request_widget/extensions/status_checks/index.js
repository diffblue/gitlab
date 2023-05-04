import * as Sentry from '@sentry/browser';

import { __, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import * as StatusCheckRetryApi from 'ee/api/status_check_api';
import Poll from '~/lib/utils/poll';
import { responseHasPendingChecks } from 'ee/vue_merge_request_widget/extensions/status_checks/utils';
import { LOADING_STATES } from '~/vue_merge_request_widget/components/extensions/base.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

import { getFailedChecksWithLoadingState, mapStatusCheckResponse } from './mappers';

export default {
  name: 'WidgetStatusChecks',
  i18n: {
    label: s__('StatusCheck|status checks'),
    loading: s__('StatusCheck|Status checks are being fetched'),
    error: s__('StatusCheck|Failed to load status checks'),
  },
  props: ['apiStatusChecksPath'],
  data() {
    return {
      poll: null,
    };
  },
  beforeDestroy() {
    this.stopPolling();
  },
  computed: {
    // Extension computed props
    summary({ approved = [], pending = [], failed = [] }) {
      if (approved.length > 0 && failed.length === 0 && pending.length === 0) {
        return s__('StatusCheck|Status checks all passed');
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
        subject: s__('StatusCheck|Status checks'),
        meta: reports.join(__(', ')),
      };
    },
    statusIcon({ pending = [], failed = [] }) {
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

      if (this.hasFetchError) {
        actionButtons.push({
          text: __('Retry'),
          onClick: () => this.loadCollapsedData(),
        });
      }

      actionButtons.push({
        icon: 'information-o',
        class: 'btn-icon',
        id: 'info-status-checks-id',
        popoverTarget: 'info-status-checks-id',
        popoverTitle: s__('StatusCheck|What is status check?'),
        popoverText: s__(
          'StatusCheck|Status checks are API calls to external systems that request the status of an external requirement. %{linkStart}Learn more.%{linkEnd}',
        ),
        popoverLink: helpPagePath('user/project/merge_requests/status_checks'),
        testId: 'info-status-checks',
      });

      return actionButtons;
    },
  },
  methods: {
    // Extension methods
    async fetchCollapsedData() {
      const { approved, pending, failed } = this.collapsedData;
      const hasData = Boolean(approved && pending && failed);

      if (!hasData) {
        this.startPolling();
      }

      return this.collapsedData;
    },
    async fetchFullData() {
      const { approved, pending, failed } = this.collapsedData;
      return [...approved, ...pending, ...failed];
    },
    // Custom methods
    async fetchStatusChecks() {
      this.loadingState = LOADING_STATES.collapsedLoading;
      return axios.get(this.apiStatusChecksPath);
    },
    async retryStatusCheck(statusCheck) {
      const { approved, pending, failed } = this.collapsedData;
      const failedChecksWithLoading = getFailedChecksWithLoadingState(failed, statusCheck.id);
      this.setFullData([...approved, ...pending, ...failedChecksWithLoading]);

      try {
        await StatusCheckRetryApi.mrStatusCheckRetry({
          projectId: this.mr.targetProjectId,
          mergeRequestId: this.mr.iid,
          externalStatusCheckId: statusCheck.id,
        });
        const data = await this.fetchCollapsedData();
        this.setCollapsedData(data);
      } catch (err) {
        if (err?.response?.status === HTTP_STATUS_UNPROCESSABLE_ENTITY) {
          const data = await this.fetchCollapsedData();
          this.setCollapsedData(data);
          return;
        }

        this.setFullData([...approved, ...pending, ...failed]);
        Sentry.captureException(err);
      }
    },
    startPolling() {
      this.poll = new Poll({
        resource: {
          fetchData: async () => this.fetchStatusChecks(),
        },
        method: 'fetchData',
        successCallback: (response) => {
          if (!responseHasPendingChecks(response)) {
            this.stopPolling();
          }

          const data = mapStatusCheckResponse(
            response,
            {
              canRetry: this.mr.canRetryExternalStatusChecks,
            },
            (statusCheck) => this.retryStatusCheck(statusCheck),
          );
          this.setCollapsedData(data);
        },
        errorCallback: (e) => this.setCollapsedError(e),
      });

      this.poll.makeDelayedRequest(1);
    },
    stopPolling() {
      this.poll?.stop();
      this.poll = null;
    },
  },
};
