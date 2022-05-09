import { s__, n__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';
import { parseDependencies } from './utils';

// TODO: Clean up both status versions as part of https://gitlab.com/gitlab-org/gitlab/-/issues/356206
const APPROVAL_STATUS_TO_ICON = {
  allowed: EXTENSION_ICONS.success,
  approved: EXTENSION_ICONS.success,
  denied: EXTENSION_ICONS.failed,
  blacklisted: EXTENSION_ICONS.failed,
  unclassified: EXTENSION_ICONS.notice,
};

export default {
  name: 'WidgetLicenseCompliance',
  i18n: {
    label: s__('ciReport|License Compliance'),
    loading: s__('ciReport|License Compliance test metrics results are being parsed'),
    error: s__('ciReport|License Compliance failed loading results'),
  },
  expandEvent: 'i_testing_license_compliance_widget_total',
  props: ['licenseCompliance'],
  computed: {
    newLicenses() {
      return this.collapsedData[0].new_licenses || [];
    },
    licenseReportLength() {
      return this.newLicenses().length;
    },
    hasReportItems() {
      return this.licenseReportLength() > 0;
    },
    hasBaseReportLicenses() {
      return this.collapsedData[0].existing_licenses?.length > 0;
    },
    hasDeniedLicense() {
      return (this.newLicenses() || []).some(
        (license) => license.approvalStatus === LICENSE_APPROVAL_STATUS.DENIED,
      );
    },
    summary() {
      if (this.hasReportItems()) {
        if (this.hasBaseReportLicenses()) {
          return this.hasDeniedLicense()
            ? n__(
                'LicenseCompliance|License Compliance detected %d new license and policy violation',
                'LicenseCompliance|License Compliance detected %d new licenses and policy violations',
                this.licenseReportLength(),
              )
            : n__(
                'LicenseCompliance|License Compliance detected %d new license',
                'LicenseCompliance|License Compliance detected %d new licenses',
                this.licenseReportLength(),
              );
        }

        return this.hasDeniedLicense()
          ? n__(
              'LicenseCompliance|License Compliance detected %d license and policy violation for the source branch only',
              'LicenseCompliance|License Compliance detected %d licenses and policy violations for the source branch only',
              this.licenseReportLength(),
            )
          : n__(
              'LicenseCompliance|License Compliance detected %d license for the source branch only',
              'LicenseCompliance|License Compliance detected %d licenses for the source branch only',
              this.licenseReportLength(),
            );
      }

      if (this.hasBaseReportLicenses()) {
        return s__('LicenseCompliance|License Compliance detected no new licenses');
      }

      return s__(
        'LicenseCompliance|License Compliance detected no licenses for the source branch only',
      );
    },
    statusIcon() {
      if (this.collapsedData[0].new_licenses?.length === 0) {
        return EXTENSION_ICONS.success;
      }
      return EXTENSION_ICONS.warning;
    },
  },
  methods: {
    fetchCollapsedData() {
      const { license_scanning_comparison_path } = this.licenseCompliance;

      return Promise.all([this.fetchReport(license_scanning_comparison_path)]).then(
        (values) => values,
      );
    },
    fetchFullData() {
      const { license_scanning_comparison_path } = this.licenseCompliance;

      return Promise.all([this.fetchReport(license_scanning_comparison_path)]).then((values) => {
        let newLicenses = values[0].new_licenses;

        newLicenses = newLicenses.map((e) => ({
          status: e.classification.approval_status,
          icon: {
            name: APPROVAL_STATUS_TO_ICON[e.classification.approval_status],
          },
          link: {
            href: e.url,
            text: e.name,
          },
          supportingText: `${s__('License Compliance| Used by')} ${parseDependencies(
            e.dependencies,
          )}`,
        }));

        const groupedLicenses = newLicenses.reduce(
          (licenses, license) => ({
            ...licenses,
            [license.status]: [...(licenses[license.status] || []), license],
          }),
          {},
        );

        // TODO: Clean up both status versions as part of https://gitlab.com/gitlab-org/gitlab/-/issues/356206
        const licenseSections = [
          ...(groupedLicenses.denied?.length > 0 || groupedLicenses.blacklisted?.length > 0
            ? [
                {
                  header: s__('LicenseCompliance|Denied'),
                  text: s__(
                    "LicenseCompliance|Out-of-compliance with the project's policies and should be removed",
                  ),
                  children: groupedLicenses.denied || groupedLicenses.blacklisted,
                },
              ]
            : []),
          ...(groupedLicenses.unclassified?.length > 0
            ? [
                {
                  header: s__('LicenseCompliance|Uncategorized'),
                  text: s__('LicenseCompliance|No policy matches this license'),
                  children: groupedLicenses.unclassified,
                },
              ]
            : []),
          ...(groupedLicenses.allowed?.length > 0 || groupedLicenses.approved?.length > 0
            ? [
                {
                  header: s__('LicenseCompliance|Allowed'),
                  text: s__('LicenseCompliance|Acceptable for use in this project'),

                  children: groupedLicenses.allowed || groupedLicenses.approved,
                },
              ]
            : []),
        ];

        return licenseSections;
      });
    },
    fetchReport(endpoint) {
      return axios.get(endpoint).then((res) => res.data);
    },
  },
};
