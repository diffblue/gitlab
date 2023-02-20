import * as Sentry from '@sentry/browser';
import { __, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import * as StatusCheckRetryApi from 'ee/api/status_check_api';

import { mapStatusCheckResponse, getFailedChecksWithLoadingState } from './mappers';

export default {
  name: 'WidgetStatusChecks',
  i18n: {
    label: s__('StatusCheck|status checks'),
    loading: s__('StatusCheck|Status checks are being fetched'),
    error: s__('StatusCheck|Failed to load status checks'),
  },
  props: ['apiStatusChecksPath'],
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
      if (this.hasFetchError) {
        return [
          {
            text: __('Retry'),
            onClick: () => this.loadCollapsedData(),
          },
        ];
      }

      return [];
    },
  },
  methods: {
    // Extension methods
    async fetchCollapsedData() {
      const response = await this.fetchStatusChecks(this.apiStatusChecksPath);

      return mapStatusCheckResponse(
        response,
        {
          canRetry: this.mr.canRetryExternalStatusChecks,
        },
        (statusCheck) => this.retryStatusCheck(statusCheck),
      );
    },
    async fetchFullData() {
      const { approved, pending, failed } = this.collapsedData;

      return [...approved, ...pending, ...failed];
    },
    // Custom methods
    async fetchStatusChecks(endpoint) {
      return axios.get(endpoint);
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
        const statusChecks = await this.fetchCollapsedData();
        this.setFullData(Object.values(statusChecks).flat());
      } catch (err) {
        if (err?.response?.status === HTTP_STATUS_UNPROCESSABLE_ENTITY) {
          const statusChecks = await this.fetchCollapsedData();
          this.setFullData(Object.values(statusChecks).flat());
          return;
        }

        this.setFullData([...approved, ...pending, ...failed]);
        Sentry.captureException(err);
      }
    },
  },
};
