import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import EnvironmentApproval from './components/environment_approval.vue';

export const initDeploymentApprovals = () => {
  const els = document.querySelectorAll('.js-deployment-approval');

  els.forEach((el) => {
    const {
      name,
      tier,
      deployableName,
      pendingApprovalCount,
      iid,
      id,
      requiredApprovalCount,
      approvals: approvalsString,
      projectId,
      canApproveDeployment,
    } = el.dataset;

    try {
      const approvals = JSON.parse(approvalsString).map((a) =>
        convertObjectPropsToCamelCase(a, { deep: true }),
      );

      const environment = {
        upcomingDeployment: {
          deployable: {
            name: deployableName,
          },
          iid,
          id,
          pendingApprovalCount: parseInt(pendingApprovalCount, 10),
          approvals,
          canApproveDeployment: parseBoolean(canApproveDeployment),
        },
        name,
        tier,
        requiredApprovalCount: parseInt(requiredApprovalCount, 10),
      };

      // eslint-disable-next-line no-new
      new Vue({
        el,
        provide: { projectId },
        render(h) {
          return h(EnvironmentApproval, {
            props: { environment, showText: false },
            on: {
              change: () => {
                window.location.reload();
              },
            },
          });
        },
      });
    } catch (e) {
      Sentry.captureException(e);
    }
  });
};
