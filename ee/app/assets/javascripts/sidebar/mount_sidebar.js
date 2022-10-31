import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { IssuableType } from '~/issues/constants';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import SidebarDropdown from '~/sidebar/components/sidebar_dropdown.vue';
import * as CEMountSidebar from '~/sidebar/mount_sidebar';
import CveIdRequest from './components/cve_id_request/cve_id_request_sidebar.vue';
import IterationDropdown from './components/iteration_dropdown.vue';
import IterationSidebarDropdownWidget from './components/iteration_sidebar_dropdown_widget.vue';
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

const mountHealthStatusComponent = (store) => {
  const el = document.querySelector('.js-sidebar-health-status-entry-point');

  if (!el) {
    return null;
  }

  const { iid, fullPath, issuableType, canEdit } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarHealthStatusWidgetRoot',
    apolloProvider,
    store,
    provide: {
      canUpdate: parseBoolean(canEdit),
      fullPath,
      iid,
      issuableType,
    },
    render: (createElement) => createElement(SidebarHealthStatusWidget),
  });
};

export function mountHealthStatusDropdown() {
  const el = document.getElementById('js-bulk-update-health-status-root');
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

export function mountEpicDropdown() {
  const el = document.getElementById('js-epic-dropdown-root');
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
          issuableType: IssuableType.Issue,
        },
        on: {
          change: this.handleChange.bind(this),
        },
      });
    },
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

export function mountIterationDropdown() {
  const el = document.querySelector('#js-iteration-dropdown');
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
  mountHealthStatusComponent(store);
  mountEpicsSelect();
  mountIterationSelect();
  mountEscalationPoliciesSelect();
  mountCveIdRequestComponent(store);
}
