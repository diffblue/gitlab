import { s__, sprintf, __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import {
  EXTENSION_ICONS,
  EXTENSION_SUMMARY_FAILED_CLASS,
  EXTENSION_SUMMARY_NEUTRAL_CLASS,
} from '~/vue_merge_request_widget/constants';
import { PASSED, PENDING } from 'ee/reports/status_checks_report/constants';

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
          `<strong class="${EXTENSION_SUMMARY_FAILED_CLASS}">${sprintf(
            s__('StatusCheck|%{failed} failed'),
            {
              failed: failed.length,
            },
          )}</strong>`,
        );
      }
      if (pending.length > 0) {
        reports.push(
          `<strong class="${EXTENSION_SUMMARY_NEUTRAL_CLASS}">${sprintf(
            s__('StatusCheck|%{pending} pending'),
            {
              pending: pending.length,
            },
          )}</strong>`,
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
    fetchCollapsedData() {
      return this.fetchStatusChecks(this.apiStatusChecksPath).then(this.compareStatusChecks);
    },
    fetchFullData() {
      const { approved, pending, failed } = this.collapsedData;
      return Promise.resolve([...approved, ...pending, ...failed]);
    },
    // Custom methods
    fetchStatusChecks(endpoint) {
      return axios.get(endpoint).then(({ data }) => data);
    },
    createReportRow(statusCheck, iconName) {
      return {
        id: statusCheck.id,
        text: `${statusCheck.name}: ${statusCheck.external_url}`,
        icon: { name: iconName },
      };
    },
    compareStatusChecks(statusChecks) {
      const approved = [];
      const pending = [];
      const failed = [];

      statusChecks.forEach((statusCheck) => {
        switch (statusCheck.status) {
          case PASSED:
            approved.push(this.createReportRow(statusCheck, EXTENSION_ICONS.success));
            break;
          case PENDING:
            pending.push(this.createReportRow(statusCheck, EXTENSION_ICONS.neutral));
            break;
          default:
            failed.push(this.createReportRow(statusCheck, EXTENSION_ICONS.failed));
        }
      });

      return { approved, pending, failed };
    },
  },
};
