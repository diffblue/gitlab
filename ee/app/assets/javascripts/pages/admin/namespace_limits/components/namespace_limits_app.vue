<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlLink } from '@gitlab/ui';
import ExcludedNamespaces from './excluded_namespaces.vue';

export default {
  name: 'NamespaceLimitsApp',
  components: {
    GlLink,
    ExcludedNamespaces,
  },
};
</script>

<template>
  <div>
    <h2>Notifications Limit</h2>
    <div class="gl-bg-gray-10 gl-p-5 gl-border-1 gl-border-solid gl-border-blue-200">
      <p>Placeholder for notifications limit component</p>
      <h5>Changelog</h5>
      <ul>
        <li>
          <gl-link href="https://gitlab.com/gitlab-bot" target="_blank">@admin</gl-link>
          changed the limit to 150GB at 2023-03-28 15:49:00 UTC
        </li>
      </ul>
    </div>
    <hr />
    <h2>Enforcement Limit</h2>
    <div class="gl-bg-gray-10 gl-p-5 gl-border-1 gl-border-solid gl-border-blue-200">
      <p>Placeholder for enforcement limit component</p>
      <h5>Changelog</h5>
      <ul>
        <li>
          <gl-link href="https://gitlab.com/gitlab-bot" target="_blank">@admin</gl-link>
          changed the limit to 150GB at 2023-03-28 15:49:00 UTC
        </li>
      </ul>
    </div>
    <hr />
    <h2>Dashboard Limit</h2>
    <div class="gl-bg-gray-10 gl-p-5 gl-border-1 gl-border-solid gl-border-blue-200">
      <p>Placeholder for dashboard limit component</p>
      <h5>Changelog</h5>
      <ul>
        <li>
          <gl-link href="https://gitlab.com/gitlab-bot" target="_blank">@admin</gl-link>
          changed the limit to 150GB at 2023-03-28 15:49:00 UTC
        </li>
      </ul>
    </div>
    <hr />
    <h2>Excluded namespaces</h2>
    <excluded-namespaces />
  </div>
</template>
