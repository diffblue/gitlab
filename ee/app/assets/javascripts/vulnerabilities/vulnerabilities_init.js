import Vue from 'vue';
import apolloProvider from 'ee/security_dashboard/graphql/provider';
import App from 'ee/vulnerabilities/components/vulnerability.vue';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';

export default (el) => {
  if (!el) {
    return null;
  }

  const { falsePositiveDocUrl, canViewFalsePositive, projectFullPath } = el.dataset;

  const vulnerability = convertObjectPropsToCamelCase(JSON.parse(el.dataset.vulnerability), {
    deep: true,
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      reportType: vulnerability.reportType,
      newIssueUrl: vulnerability.newIssueUrl,
      commitPathTemplate: el.dataset.commitPathTemplate,
      projectFingerprint: vulnerability.projectFingerprint,
      vulnerabilityId: vulnerability.id,
      issueTrackingHelpPath: vulnerability.issueTrackingHelpPath,
      permissionsHelpPath: vulnerability.permissionsHelpPath,
      createJiraIssueUrl: vulnerability.createJiraIssueUrl,
      relatedJiraIssuesPath: vulnerability.relatedJiraIssuesPath,
      relatedJiraIssuesHelpPath: vulnerability.relatedJiraIssuesHelpPath,
      jiraIntegrationSettingsPath: vulnerability.jiraIntegrationSettingsPath,
      falsePositiveDocUrl,
      canViewFalsePositive: parseBoolean(canViewFalsePositive),
      projectFullPath,
    },
    render: (h) =>
      h(App, {
        props: { initialVulnerability: vulnerability },
      }),
  });
};
