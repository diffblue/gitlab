import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import EnvironmentApproval from './components/environment_approval.vue';

Vue.use(VueApollo);

export const initDeploymentApprovals = () => {
  const els = document.querySelectorAll('.js-deployment-approval');

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

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
      hasApprovalRules,
      projectId,
      projectPath,
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
          hasApprovalRules: parseBoolean(hasApprovalRules),
          canApproveDeployment: parseBoolean(canApproveDeployment),
        },
        name,
        tier,
        requiredApprovalCount: parseInt(requiredApprovalCount, 10),
      };

      return new Vue({
        el,
        provide: { projectId, projectPath },
        apolloProvider,
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
      return null;
    }
  });
};
