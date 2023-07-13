import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProtectedEnvironmentsApp from 'ee/protected_environments/protected_environments_app.vue';
import EditProtectedEnvironmentsList from 'ee/protected_environments/edit_protected_environments_list.vue';
import CreateProtectedEnvironment from 'ee/protected_environments/create_protected_environment.vue';

Vue.use(Vuex);

describe('ee/protected_environments/protected_environments_app.vue', () => {
  let fetchProtectedEnvironments;
  let createApp;
  let editApp;

  beforeEach(() => {
    fetchProtectedEnvironments = jest.fn();
    const store = new Vuex.Store({ actions: { fetchProtectedEnvironments } });
    const wrapper = shallowMountExtended(ProtectedEnvironmentsApp, {
      store,
    });

    createApp = wrapper.findComponent(CreateProtectedEnvironment);
    editApp = wrapper.findComponent(EditProtectedEnvironmentsList);
  });

  it('mounts the create app', () => {
    expect(createApp.exists()).toBe(true);
  });

  it('re-fetches environments when receiving reload', () => {
    createApp.vm.$emit('reload');
    expect(fetchProtectedEnvironments).toHaveBeenCalled();
  });

  it('mounts the edit app', () => {
    expect(editApp.exists()).toBe(true);
  });
});
