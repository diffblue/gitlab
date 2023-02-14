import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/issues/constants';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import SidebarDropdown from '~/sidebar/components/sidebar_dropdown.vue';
import * as CEMountSidebar from '~/sidebar/mount_sidebar';
import CveIdRequest from './components/cve_id_request/cve_id_request.vue';
import IterationDropdown from './components/iteration/iteration_dropdown.vue';
import SidebarIterationWidget from './components/iteration/sidebar_iteration_widget.vue';
import SidebarDropdownWidget from './components/sidebar_dropdown_widget.vue';
import HealthStatusDropdown from './components/health_status/health_status_dropdown.vue';
import SidebarHealthStatusWidget from './components/health_status/sidebar_health_status_widget.vue';
import SidebarWeightWidget from './components/weight/sidebar_weight_widget.vue';
import SidebarEscalationPolicy from './components/incidents/sidebar_escalation_policy.vue';
import {
  healthStatusForRestApi,
  IssuableAttributeType,
  noEpic,
  placeholderEpic,
} from './constants';

Vue.use(VueApollo);

const mountSidebarWeightWidget = () => {
  const el = document.querySelector('.js-sidebar-weight-widget-root');

  if (!el) {
    return null;
  }

  const { canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarWeightWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(SidebarWeightWidget, {
        props: {
          fullPath: projectPath,
          iid: issueIid,
          issuableType: TYPE_ISSUE,
        },
      }),
  });
};

const mountSidebarHealthStatusWidget = () => {
  const el = document.querySelector('.js-sidebar-health-status-widget-root');

  if (!el) {
    return null;
  }

  const { iid, fullPath, issuableType, canEdit } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarHealthStatusWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canEdit),
    },
    render: (createElement) =>
      createElement(SidebarHealthStatusWidget, {
        props: {
          fullPath,
          iid,
          issuableType,
        },
      }),
  });
};

export function mountHealthStatusDropdown() {
  const el = document.querySelector('.js-health-status-dropdown-root');
  const healthStatusFormInput = document.getElementById('issue_health_status_value');

  if (!el || !healthStatusFormInput) {
    return null;
  }

  return new Vue({
    el,
    name: 'HealthStatusDropdownRoot',
    data() {
      return {
        healthStatus: undefined,
      };
    },
    methods: {
      handleChange(healthStatus) {
        this.healthStatus = healthStatus;
        healthStatusFormInput.setAttribute(
          'value',
          healthStatusForRestApi[healthStatus || 'NO_STATUS'],
        );
      },
    },
    render(createElement) {
      return createElement(HealthStatusDropdown, {
        props: {
          healthStatus: this.healthStatus,
        },
        on: {
          change: this.handleChange.bind(this),
        },
      });
    },
  });
}

function mountSidebarCveIdRequest(store) {
  const el = document.querySelector('.js-sidebar-cve-id-request-root');

  if (!el) {
    return null;
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

function mountSidebarEpicWidget() {
  const el = document.querySelector('.js-sidebar-epic-widget-root');

  if (!el) {
    return null;
  }

  const { groupPath, canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarEpicWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(SidebarDropdownWidget, {
        props: {
          attrWorkspacePath: groupPath,
          workspacePath: projectPath,
          iid: issueIid,
          issuableType: TYPE_ISSUE,
          issuableAttribute: IssuableAttributeType.Epic,
        },
      }),
  });
}

export function mountEpicDropdown() {
  const el = document.querySelector('.js-epic-dropdown-root');
  const epicFormInput = document.getElementById('issue_epic_id');

  if (!el || !epicFormInput) {
    return null;
  }

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'EpicDropdownRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    data() {
      return {
        epic: placeholderEpic,
      };
    },
    methods: {
      handleChange(epic) {
        this.epic = epic.id === null ? noEpic : epic;
        epicFormInput.setAttribute('value', getIdFromGraphQLId(this.epic.id));
      },
    },
    render(createElement) {
      return createElement(SidebarDropdown, {
        props: {
          attrWorkspacePath: el.dataset.groupPath,
          currentAttribute: this.epic,
          issuableAttribute: IssuableAttributeType.Epic,
          issuableType: TYPE_ISSUE,
        },
        on: {
          change: this.handleChange.bind(this),
        },
      });
    },
  });
}

function mountSidebarIterationWidget() {
  const el = document.querySelector('.js-sidebar-iteration-widget-root');

  if (!el) {
    return null;
  }

  const { groupPath, canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarIterationWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(SidebarIterationWidget, {
        props: {
          attrWorkspacePath: groupPath,
          workspacePath: projectPath,
          iid: issueIid,
          issuableType: TYPE_ISSUE,
          issuableAttribute: IssuableAttributeType.Iteration,
        },
      }),
  });
}

export function mountIterationDropdown() {
  const el = document.querySelector('.js-iteration-dropdown-root');
  const iterationFormInput = document.getElementById('issue_iteration_id');

  if (!el || !iterationFormInput) {
    return null;
  }

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'IterationDropdownRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      fullPath: el.dataset.fullPath,
    },
    methods: {
      getIdForIteration(iteration) {
        const noChangeIterationValue = '';
        const unSetIterationValue = '0';

        if (iteration === null) {
          return noChangeIterationValue;
        } else if (iteration.id === null) {
          return unSetIterationValue;
        }

        return getIdFromGraphQLId(iteration.id);
      },
      handleIterationSelect(iteration) {
        iterationFormInput.setAttribute('value', this.getIdForIteration(iteration));
      },
    },
    render(createElement) {
      return createElement(IterationDropdown, {
        on: {
          onIterationSelect: this.handleIterationSelect.bind(this),
        },
      });
    },
  });
}

function mountSidebarEscalationPolicy() {
  const el = document.querySelector('.js-sidebar-escalation-policy-root');

  if (!el) {
    return null;
  }

  const { canEdit, projectPath, issueIid, hasEscalationPolicies } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarEscalationPolicyRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(SidebarEscalationPolicy, {
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
  mountSidebarWeightWidget();
  mountSidebarHealthStatusWidget();
  mountSidebarEpicWidget();
  mountSidebarIterationWidget();
  mountSidebarEscalationPolicy();
  mountSidebarCveIdRequest(store);
}
