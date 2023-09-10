import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import RolesAndPermissionsSelfManaged from './components/roles_and_permissions_self_managed.vue';

Vue.use(GlToast);

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
