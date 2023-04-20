import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import EnvironmentApproval from './components/environment_approval.vue';

Vue.use(VueApollo);

export const initDeploymentApprovals = () => {
  const els = document.querySelectorAll('.js-deployment-approval');

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  els.forEach((el) => {
    const { name, tier, iid, requiredApprovalCount, projectId, projectPath } = el.dataset;

    try {
      const environment = {
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
            props: { environment, deploymentIid: iid, showText: false },
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
