import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProtectedEnvironmentsApp from 'ee/protected_environments/protected_environments_app.vue';
import EditProtectedEnvironmentsList from 'ee/protected_environments/edit_protected_environments_list.vue';

Vue.use(Vuex);

describe('ee/protected_environments/protected_environments_app.vue', () => {
  let fetchProtectedEnvironments;
  let editApp;

  beforeEach(() => {
    fetchProtectedEnvironments = jest.fn();
    const store = new Vuex.Store({ actions: { fetchProtectedEnvironments } });
    const wrapper = shallowMountExtended(ProtectedEnvironmentsApp, {
      store,
    });

    editApp = wrapper.findComponent(EditProtectedEnvironmentsList);
  });

  it('mounts the app', () => {
    expect(editApp.exists()).toBe(true);
  });
});
