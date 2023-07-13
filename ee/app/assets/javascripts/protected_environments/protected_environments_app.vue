<script>
import { mapActions } from 'vuex';
import EditProtectedEnvironmentList from './edit_protected_environments_list.vue';
import CreateProtectedEnvironment from './create_protected_environment.vue';

export default {
  components: {
    CreateProtectedEnvironment,
    EditProtectedEnvironmentList,
  },
  methods: {
    ...mapActions(['fetchProtectedEnvironments']),
  },
};
</script>
<template>
  <div>
    <create-protected-environment @reload="fetchProtectedEnvironments" />
    <edit-protected-environment-list />
  </div>
</template>
