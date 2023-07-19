<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { APP_PLAN_LIMITS_ENDPOINT, APP_PLAN_LIMIT_PARAM_NAMES } from '../constants';
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
    GlAlert,
    ExcludedNamespaces,
    NamespaceLimitsSection,
  },
  data() {
    return {
      loadingError: null,
      notificationsLimitError: '',
      enforcementLimitError: '',
      dashboardLimitError: '',
      plan: {},
    };
  },
  i18n,
  created() {
    this.fetchPlanData();
  },
  methods: {
    async fetchPlanData() {
      this.loadingError = null;
      const endpoint = Api.buildUrl(APP_PLAN_LIMITS_ENDPOINT);
      try {
        const response = await axios.get(endpoint, { params: { plan_name: 'free' } });
        this.plan = response.data;
      } catch {
        this.loadingError = s__(
          'NamespaceLimits|Namespace limits could not be loaded. Reload the page to try again.',
        );
      }
    },
    async updateLimit(limit, limitType) {
      const endpoint = Api.buildUrl(APP_PLAN_LIMITS_ENDPOINT);
      try {
        const response = await axios.put(endpoint, undefined, {
          params: {
            plan_name: 'free',
            [limitType]: limit,
          },
        });
        this.plan = response.data;
      } catch (error) {
        throw error?.response?.data?.message ?? error?.message;
      }
    },
    async handleNotificationsLimitChange(limit) {
      // clear any previous errors
      this.notificationsLimitError = null;
      try {
        await this.updateLimit(limit, APP_PLAN_LIMIT_PARAM_NAMES.notifications);
        const toastMessage =
          limit === '0'
            ? s__('NamespaceLimits|Notifications limit was successfully removed')
            : s__('NamespaceLimits|Notifications limit was successfully added');
        this.$toast.show(toastMessage);
      } catch (error) {
        this.notificationsLimitError = error;
      }
    },
    async handleEnforcementLimitChange(limit) {
      // clear any previous errors
      this.enforcementLimitError = null;
      try {
        await this.updateLimit(limit, APP_PLAN_LIMIT_PARAM_NAMES.enforcement);
        const toastMessage =
          limit === '0'
            ? s__('NamespaceLimits|Enforcement limit was successfully removed')
            : s__('NamespaceLimits|Enforcement limit was successfully added');
        this.$toast.show(toastMessage);
      } catch (error) {
        this.enforcementLimitError = error;
      }
    },
    async handleDashboardLimitChange(limit) {
      // clear any previous errors
      this.dashboardLimitError = null;
      try {
        await this.updateLimit(limit, APP_PLAN_LIMIT_PARAM_NAMES.dashboard);
        const toastMessage =
          limit === '0'
            ? s__('NamespaceLimits|Dashboard limit was successfully removed')
            : s__('NamespaceLimits|Dashboard limit was successfully added');

        this.$toast.show(toastMessage);
      } catch (error) {
        this.dashboardLimitError = error;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false" class="gl-mb-4">
      {{ loadingError }}
    </gl-alert>

    <h2>{{ $options.i18n.notificationsLimitTitle }}</h2>
    <namespace-limits-section
      :limit="plan.notification_limit || 0"
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
      :limit="plan.enforcement_limit || 0"
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
      :limit="plan.storage_size_limit || 0"
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
