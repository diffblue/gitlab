import { escape } from 'lodash';
import { n__, __, s__, sprintf } from '~/locale';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export default {
  name: 'WidgetSecurityReports',
  data() {
    return {
      totalVulnerabilities: 0,
      modalName: undefined,
      modalData: undefined,
    };
  },
  props: ['securityReportPaths'],
  enablePolling: true,
  i18n: {
    new: __('New'),
    fixed: __('Fixed'),
    label: s__('ciReport|Security scanning'),
    loading: s__('ciReport|Security scanning is loading'),
    sastScanner: s__('ciReport|SAST'),
    dastScanner: s__('ciReport|DAST'),
    depedencyScanner: s__('ciReport|Dependency scanning'),
    secretDetectionScanner: s__('ciReport|Secret detection'),
    coverageFuzzing: s__('ciReport|Coverage fuzzing'),
    apiFuzzing: s__('ciReport|API fuzzing'),
    securityScanning: s__('ciReport|Security scanning'),
    detected: (scanner, number) => {
      const vulnStr = n__('vulnerability', 'vulnerabilities', number);

      if (!number) {
        return sprintf(s__('ciReport|%{scanner} detected no new %{vulnStr}'), {
          vulnStr,
          scanner,
        });
      }

      return sprintf(
        s__(
          'ciReport|%{scanner} detected %{strong_start}%{number}%{strong_end} new potential %{vulnStr}',
        ),
        {
          vulnStr,
          scanner,
          number,
        },
      );
    },
    error: s__('ciReport|Security reports failed loading results'),
  },
  modalComponent: IssueModal,
  computed: {
    summary() {
      return this.$options.i18n.detected(
        this.$options.i18n.securityScanning,
        this.totalVulnerabilities(),
      );
    },
    statusIcon() {
      if (this.totalVulnerabilities() > 0) {
        return EXTENSION_ICONS.warning;
      }

      return EXTENSION_ICONS.success;
    },
  },
  methods: {
    totalVulnerabilities() {
      return (
        this.collapsedData.reduce((sum, vulnData) => {
          return sum + (vulnData.added?.length || 0);
        }, 0) || 0
      );
    },
    listVulnerabilities(vulns, header) {
      if (!vulns?.length) {
        return [];
      }

      return [
        {
          text: `<b class="gl-display-inline-block gl-my-4">${escape(header)}</b>`,
        },
        ...vulns.map((vuln) => ({
          modal: {
            text: `${SEVERITY_LEVELS[vuln.severity]} ${vuln.name}`,
            onClick: () => {
              this.modalName = VULNERABILITY_MODAL_ID;
              this.modalData = {
                modal: {
                  title: vuln.name,
                  vulnerability: vuln,
                },
                visible: true,
                isCreatingIssue: false,
                isCreatingMergeRequest: false,
                isDismissingVulnerability: true,
              };
            },
          },
          icon: {
            name: EXTENSION_ICONS[`severity${capitalizeFirstCharacter(vuln.severity)}`],
          },
        })),
      ];
    },
    fetchMultiData() {
      const {
        sastReportPath,
        dastReportPath,
        secretDetectionReportPath,
        apiFuzzingReportPath,
        coverageFuzzingReportPath,
        dependencyScanningReportPath,
      } = this.securityReportPaths;

      const endpoints = [
        [sastReportPath, this.$options.i18n.sastScanner],
        [dastReportPath, this.$options.i18n.dastScanner],
        [secretDetectionReportPath, this.$options.i18n.secretDetectionScanner],
        [apiFuzzingReportPath, this.$options.i18n.apiFuzzing],
        [coverageFuzzingReportPath, this.$options.i18n.coverageFuzzing],
        [dependencyScanningReportPath, this.$options.i18n.dependencyScanner],
      ];

      return endpoints.map(([path, reportType]) => () => this.fetchReport(path, reportType));
    },
    fetchFullData() {
      return Promise.resolve(
        this.collapsedData.map((data) => ({
          text: this.$options.i18n.detected(data.reportType, data.added?.length),
          icon: {
            name: data.added?.length ? EXTENSION_ICONS.warning : EXTENSION_ICONS.success,
          },
          children: [
            ...this.listVulnerabilities(data.added, this.$options.i18n.new),
            ...this.listVulnerabilities(data.fixed, this.$options.i18n.fixed),
          ],
        })),
      );
    },
    fetchReport(endpoint, reportType) {
      if (!endpoint) {
        return Promise.resolve();
      }

      return axios.get(endpoint).then((r) => ({ ...r, data: { ...r.data, reportType } }));
    },
  },
};
