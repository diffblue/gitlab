import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { IssuableType } from '~/issues/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/sidebar/graphql';
import * as CEMountSidebar from '~/sidebar/mount_sidebar';
import CveIdRequest from './components/cve_id_request/cve_id_request_sidebar.vue';
import IterationSidebarDropdownWidget from './components/iteration_sidebar_dropdown_widget.vue';
import SidebarDropdownWidget from './components/sidebar_dropdown_widget.vue';
import SidebarStatus from './components/status/sidebar_status.vue';
import SidebarWeightWidget from './components/weight/sidebar_weight_widget.vue';
import SidebarEscalationPolicy from './components/incidents/sidebar_escalation_policy.vue';
import { IssuableAttributeType } from './constants';

Vue.use(VueApollo);

const mountWeightComponent = () => {
  const el = document.querySelector('.js-sidebar-weight-entry-point');

  if (!el) return false;

  const { canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarWeightRoot',
    apolloProvider,
    components: {
      SidebarWeightWidget,
    },
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement('sidebar-weight-widget', {
        props: {
          fullPath: projectPath,
          iid: issueIid,
          issuableType: IssuableType.Issue,
        },
      }),
  });
};

const mountStatusComponent = (store) => {
  const el = document.querySelector('.js-sidebar-status-entry-point');

  if (!el) {
    return false;
  }

  const { iid, fullPath, issuableType, canEdit } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarHealthStatusRoot',
    apolloProvider,
    store,
    components: {
      SidebarStatus,
    },
    render: (createElement) =>
      createElement('sidebar-status', {
        props: {
          issuableType,
          iid,
          fullPath,
          canUpdate: parseBoolean(canEdit),
        },
      }),
  });
};

function mountCveIdRequestComponent(store) {
  const el = document.getElementById('js-sidebar-cve-id-request-entry-point');

  if (!el) {
    return false;
  }

  const { iid, fullPath } = CEMountSidebar.getSidebarOptions();

  return new Vue({
    store,
    el,
    name: 'SidebarCveIdRequestRoot',
    provide: {
      iid: String(iid),
      fullPath,
    },
    render: (createElement) => createElement(CveIdRequest),
  });
}

function mountEpicsSelect() {
  const el = document.querySelector('#js-vue-sidebar-item-epics-select');

  if (!el) return false;

  const { groupPath, canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarEpicRoot',
    apolloProvider,
    components: {
      SidebarDropdownWidget,
    },
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement('sidebar-dropdown-widget', {
        props: {
          attrWorkspacePath: groupPath,
          workspacePath: projectPath,
          iid: issueIid,
          issuableType: IssuableType.Issue,
          issuableAttribute: IssuableAttributeType.Epic,
        },
      }),
  });
}

function mountIterationSelect() {
  const el = document.querySelector('.js-iteration-select');

  if (!el) {
    return false;
  }

  const { groupPath, canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarIterationRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(IterationSidebarDropdownWidget, {
        props: {
          attrWorkspacePath: groupPath,
          workspacePath: projectPath,
          iid: issueIid,
          issuableType: IssuableType.Issue,
          issuableAttribute: IssuableAttributeType.Iteration,
        },
      }),
  });
}

function mountEscalationPoliciesSelect() {
  const el = document.querySelector('#js-escalation-policy');

  if (!el) {
    return false;
  }

  const { canEdit, projectPath, issueIid, hasEscalationPolicies } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarEscalationPolicyRoot',
    apolloProvider,
    components: {
      SidebarEscalationPolicy,
    },
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement('sidebar-escalation-policy', {
        props: {
          projectPath,
          iid: issueIid,
          escalationsPossible: parseBoolean(hasEscalationPolicies),
        },
      }),
  });
}

export const { getSidebarOptions } = CEMountSidebar;

export function mountSidebar(mediator, store) {
  CEMountSidebar.mountSidebar(mediator, store);
  mountWeightComponent();
  mountStatusComponent(store);
  mountEpicsSelect();
  mountIterationSelect();
  mountEscalationPoliciesSelect();
  mountCveIdRequestComponent(store);
}
