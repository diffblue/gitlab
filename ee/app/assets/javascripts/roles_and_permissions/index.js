import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import RolesAndPermissionsSaas from './components/roles_and_permissions_saas.vue';
import RolesAndPermissionsSelfManaged from './components/roles_and_permissions_self_managed.vue';

Vue.use(GlToast);

export const initRolesAndPermissionsSaasApp = () => {
  const el = document.querySelector('#js-roles-and-permissions-saas');

  if (!el) {
    return null;
  }
  const { groupId } = el.dataset;

  return new Vue({
    el,
    name: 'RolesAndPermissionsSaasRoot',
    render(h) {
      return h(RolesAndPermissionsSaas, { props: { groupId } });
    },
  });
};

export const initRolesAndPermissionsSelfManagedApp = () => {
  const el = document.querySelector('#js-roles-and-permissions-self-managed');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'RolesAndPermissionsSelfManagedRoot',
    render(h) {
      return h(RolesAndPermissionsSelfManaged);
    },
  });
};
