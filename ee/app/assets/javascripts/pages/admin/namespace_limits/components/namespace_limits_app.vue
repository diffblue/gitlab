<script>
import { s__ } from '~/locale';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { UPDATE_FREE_PLAN_LIMITS_ENDPOINT, UPDATE_PLAN_LIMIT_PARAM_NAMES } from '../constants';
import ExcludedNamespaces from './excluded_namespaces.vue';
import NamespaceLimitsSection from './namespace_limits_section.vue';

const i18n = {
  excludedNamespacesTitle: s__('NamespaceLimits|Excluded Namespaces'),
  notificationsLimitTitle: s__('NamespaceLimits|Notifications Limit'),
  notificationsLimitLabel: s__('NamespaceLimits|Set Notifications limit'),
  notificationsLimitDescription: s__(
    'NamespaceLimits|Add minimum free storage amount (in MiB) that will be used to show notifications for namespace on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
  ),
  notificationsLimitModalBody: s__(
    'NamespaceLimits|This will limit the amount of notifications all free namespaces receives except the excluded namespaces, the limit can be removed later.',
  ),
  enforcementLimitTitle: s__('NamespaceLimits|Enforcement Limit'),
  enforcementLimitLabel: s__('NamespaceLimits|Set Enforcement limit'),
  enforcementLimitDescription: s__(
    'NamespaceLimits|Add minimum free storage amount (in MiB) that will be used to enforce storage usage for namespaces on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
  ),
  enforcementLimitModalBody: s__(
    'NamespaceLimits|This will change when free namespaces get storage enforcement except the excluded namespaces, the limit can be removed later.',
  ),
  dashboardLimitTitle: s__('NamespaceLimits|Dashboard Limit'),
  dashboardLimitLabel: s__('NamespaceLimits|Set Dashboard limit'),
  dashboardLimitDescription: s__(
    'NamespaceLimits|Add minimum free storage amount (in MiB) that will be used to set the dashboard limit for namespaces on free plan. To remove the limit, set the value to 0 and click "Update limit" button.',
  ),
  dashboardLimitModalBody: s__(
    'NamespaceLimits|This will change the dashboard limit for all free namespaces except the excluded namespaces, the limit can be removed later.',
  ),
};

export default {
  name: 'NamespaceLimitsApp',
  components: {
    ExcludedNamespaces,
    NamespaceLimitsSection,
  },
  data() {
    return {
      notificationsLimitError: '',
      enforcementLimitError: '',
      dashboardLimitError: '',
    };
  },
  i18n,
  methods: {
    async handleNotificationsLimitChange(limit) {
      // clear any previous errors
      this.notificationsLimitError = null;

      const endpoint = Api.buildUrl(UPDATE_FREE_PLAN_LIMITS_ENDPOINT);
      const updateNotificationsLimitUrl = `${endpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.notifications}=${limit}`;

      try {
        await axios.put(updateNotificationsLimitUrl);

        const toastMessage =
          limit === '0'
            ? s__('NamespaceLimits|Notifications limit was successfully removed')
            : s__('NamespaceLimits|Notifications limit was successfully added');

        this.$toast.show(toastMessage);
      } catch (error) {
        this.notificationsLimitError = error?.response?.data?.message || error.message;
      }
    },
    async handleEnforcementLimitChange(limit) {
      // clear any previous errors
      this.enforcementLimitError = null;

      const endpoint = Api.buildUrl(UPDATE_FREE_PLAN_LIMITS_ENDPOINT);
      const updateEnforcementLimitUrl = `${endpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.enforcement}=${limit}`;

      try {
        await axios.put(updateEnforcementLimitUrl);

        const toastMessage =
          limit === '0'
            ? s__('NamespaceLimits|Enforcement limit was successfully removed')
            : s__('NamespaceLimits|Enforcement limit was successfully added');

        this.$toast.show(toastMessage);
      } catch (error) {
        this.enforcementLimitError = error?.response?.data?.message || error.message;
      }
    },
    async handleDashboardLimitChange(limit) {
      // clear any previous errors
      this.dashboardLimitError = null;

      const endpoint = Api.buildUrl(UPDATE_FREE_PLAN_LIMITS_ENDPOINT);
      const updateDashboardLimitUrl = `${endpoint}&${UPDATE_PLAN_LIMIT_PARAM_NAMES.dashboard}=${limit}`;

      try {
        await axios.put(updateDashboardLimitUrl);

        const toastMessage =
          limit === '0'
            ? s__('NamespaceLimits|Dashboard limit was successfully removed')
            : s__('NamespaceLimits|Dashboard limit was successfully added');

        this.$toast.show(toastMessage);
      } catch (error) {
        this.dashboardLimitError = error?.response?.data?.message || error.message;
      }
    },
  },
};
</script>

<template>
  <div>
    <h2>{{ $options.i18n.notificationsLimitTitle }}</h2>
    <namespace-limits-section
      :label="$options.i18n.notificationsLimitLabel"
      :description="$options.i18n.notificationsLimitDescription"
      :error-message="notificationsLimitError"
      :modal-body="$options.i18n.notificationsLimitModalBody"
      data-testid="notifications-limit-section"
      @limit-change="handleNotificationsLimitChange"
    />
    <hr />
    <h2>{{ $options.i18n.enforcementLimitTitle }}</h2>
    <namespace-limits-section
      :label="$options.i18n.enforcementLimitLabel"
      :description="$options.i18n.enforcementLimitDescription"
      :error-message="enforcementLimitError"
      :modal-body="$options.i18n.enforcementLimitModalBody"
      data-testid="enforcement-limit-section"
      @limit-change="handleEnforcementLimitChange"
    />
    <hr />
    <h2>{{ $options.i18n.dashboardLimitTitle }}</h2>
    <namespace-limits-section
      :label="$options.i18n.dashboardLimitLabel"
      :description="$options.i18n.dashboardLimitDescription"
      :error-message="dashboardLimitError"
      :modal-body="$options.i18n.dashboardLimitModalBody"
      data-testid="dashboard-limit-section"
      @limit-change="handleDashboardLimitChange"
    />
    <hr />
    <h2>{{ $options.i18n.excludedNamespacesTitle }}</h2>
    <excluded-namespaces />
  </div>
</template>
