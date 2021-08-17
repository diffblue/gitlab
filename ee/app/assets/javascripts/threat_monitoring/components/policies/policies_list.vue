<script>
import {
  GlTable,
  GlEmptyState,
  GlAlert,
  GlSprintf,
  GlLink,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { PREDEFINED_NETWORK_POLICIES } from 'ee/threat_monitoring/constants';
import createFlash from '~/flash';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { setUrlFragment, mergeUrlParams } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import networkPoliciesQuery from '../../graphql/queries/network_policies.query.graphql';
import scanExecutionPoliciesQuery from '../../graphql/queries/scan_execution_policies.query.graphql';
import { getPolicyType } from '../../utils';
import { POLICY_TYPE_COMPONENT_OPTIONS, POLICY_TYPE_OPTIONS } from '../constants';
import EnvironmentPicker from '../environment_picker.vue';
import PolicyDrawer from '../policy_drawer/policy_drawer.vue';
import PolicyEnvironments from '../policy_environments.vue';
import PolicyTypeFilter from '../policy_type_filter.vue';

const createPolicyFetchError = ({ gqlError, networkError }) => {
  const error =
    gqlError?.message ||
    networkError?.message ||
    s__('NetworkPolicies|Something went wrong, unable to fetch policies');
  createFlash({
    message: error,
  });
};

const getPoliciesWithType = (policies, policyType) =>
  policies.map((policy) => ({
    ...policy,
    policyType,
  }));

export default {
  components: {
    GlTable,
    GlEmptyState,
    GlAlert,
    GlSprintf,
    GlLink,
    GlIcon,
    EnvironmentPicker,
    PolicyTypeFilter,
    PolicyDrawer,
    PolicyEnvironments,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath', 'documentationPath', 'newPolicyPath'],
  props: {
    shouldUpdatePolicyList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    networkPolicies: {
      query: networkPoliciesQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          environmentId: this.allEnvironments ? null : this.currentEnvironmentGid,
        };
      },
      update(data) {
        const policies = data?.project?.networkPolicies?.nodes ?? [];
        const predefined = PREDEFINED_NETWORK_POLICIES.filter(
          ({ name }) => !policies.some((policy) => name === policy.name),
        );
        return [...policies, ...predefined];
      },
      error: createPolicyFetchError,
      skip() {
        return this.isLoadingEnvironments || !this.shouldShowNetworkPolicies;
      },
    },
    scanExecutionPolicies: {
      query: scanExecutionPoliciesQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data?.project?.scanExecutionPolicies?.nodes ?? [];
      },
      error: createPolicyFetchError,
    },
  },
  data() {
    return {
      selectedPolicy: null,
      networkPolicies: [],
      scanExecutionPolicies: [],
      selectedPolicyType: POLICY_TYPE_OPTIONS.ALL.value,
    };
  },
  computed: {
    ...mapState('threatMonitoring', [
      'currentEnvironmentId',
      'allEnvironments',
      'isLoadingEnvironments',
    ]),
    ...mapGetters('threatMonitoring', ['currentEnvironmentGid']),
    allPolicyTypes() {
      return {
        [POLICY_TYPE_OPTIONS.POLICY_TYPE_NETWORK.value]: this.networkPolicies,
        [POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value]: this.scanExecutionPolicies,
      };
    },
    documentationFullPath() {
      return setUrlFragment(this.documentationPath, 'container-network-policy');
    },
    shouldShowNetworkPolicies() {
      return [
        POLICY_TYPE_OPTIONS.ALL.value,
        POLICY_TYPE_OPTIONS.POLICY_TYPE_NETWORK.value,
      ].includes(this.selectedPolicyType);
    },
    policies() {
      const policyTypes =
        this.selectedPolicyType === POLICY_TYPE_OPTIONS.ALL.value
          ? Object.keys(this.allPolicyTypes)
          : [this.selectedPolicyType];
      const policies = policyTypes.map((type) =>
        getPoliciesWithType(this.allPolicyTypes[type], POLICY_TYPE_OPTIONS[type].text),
      );

      return policies.flat();
    },
    isLoadingPolicies() {
      return (
        this.isLoadingEnvironments ||
        this.$apollo.queries.networkPolicies.loading ||
        this.$apollo.queries.scanExecutionPolicies.loading
      );
    },
    hasSelectedPolicy() {
      return Boolean(this.selectedPolicy);
    },
    hasAutoDevopsPolicy() {
      return Boolean(this.networkPolicies?.some((policy) => policy.fromAutoDevops));
    },
    editPolicyPath() {
      return this.hasSelectedPolicy
        ? mergeUrlParams(
            {
              environment_id: this.currentEnvironmentId,
              type: POLICY_TYPE_COMPONENT_OPTIONS[this.policyType]?.urlParameter,
            },
            this.newPolicyPath.replace('new', `${this.selectedPolicy.name}/edit`),
          )
        : '';
    },
    policyType() {
      return this.selectedPolicy ? getPolicyType(this.selectedPolicy.yaml) : 'container';
    },
    fields() {
      const environments = {
        key: 'environments',
        label: s__('SecurityPolicies|Environment(s)'),
      };
      const fields = [
        {
          key: 'status',
          label: '',
          thClass: 'gl-w-3',
          tdAttr: {
            'data-testid': 'policy-status-cell',
          },
        },
        {
          key: 'name',
          label: __('Name'),
          thClass: 'gl-w-half',
        },
        {
          key: 'policyType',
          label: s__('SecurityPolicies|Policy type'),
          sortable: true,
        },
        {
          key: 'updatedAt',
          label: __('Last modified'),
          sortable: true,
        },
      ];
      // Adds column 'environments' only while 'all environments' option is selected
      if (this.allEnvironments) fields.splice(2, 0, environments);

      return fields;
    },
  },
  watch: {
    shouldUpdatePolicyList(newShouldUpdatePolicyList) {
      if (newShouldUpdatePolicyList) {
        this.$apollo.queries.scanExecutionPolicies.refetch();
        this.$emit('update-policy-list', false);
      }
    },
  },
  methods: {
    getTimeAgoString(updatedAt) {
      if (!updatedAt) return '';
      return getTimeago().format(updatedAt);
    },
    presentPolicyDrawer(rows) {
      if (rows.length === 0) return;

      const [selectedPolicy] = rows;
      this.selectedPolicy = selectedPolicy;
    },
    deselectPolicy() {
      this.selectedPolicy = null;

      const bTable = this.$refs.policiesTable.$children[0];
      bTable.clearSelected();
    },
  },
  i18n: {
    emptyStateDescription: s__(
      `NetworkPolicies|Policies are a specification of how groups of pods are allowed to communicate with each other's network endpoints.`,
    ),
    autodevopsNoticeDescription: s__(
      `NetworkPolicies|If you are using Auto DevOps, your %{monospacedStart}auto-deploy-values.yaml%{monospacedEnd} file will not be updated if you change a policy in this section. Auto DevOps users should make changes by following the %{linkStart}Container Network Policy documentation%{linkEnd}.`,
    ),
    emptyStateButton: __('Learn more'),
    emptyStateTitle: s__('NetworkPolicies|No policies detected'),
    statusEnabled: __('Enabled'),
    statusDisabled: __('Disabled'),
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="hasAutoDevopsPolicy"
      data-testid="autodevopsAlert"
      variant="info"
      :dismissible="false"
      class="gl-mb-3"
    >
      <gl-sprintf :message="$options.i18n.autodevopsNoticeDescription">
        <template #monospaced="{ content }">
          <span class="gl-font-monospace">{{ content }}</span>
        </template>
        <template #link="{ content }">
          <gl-link :href="documentationFullPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <div class="gl-pt-5 gl-px-5 gl-bg-gray-10">
      <div class="row gl-justify-content-space-between gl-align-items-center">
        <div class="col-12 col-sm-8 col-md-6 col-lg-5 row">
          <environment-picker data-testid="environment-picker" class="col-6" :include-all="true" />
          <policy-type-filter
            v-model="selectedPolicyType"
            class="col-6"
            data-testid="policy-type-filter"
          />
        </div>
      </div>
    </div>

    <gl-table
      ref="policiesTable"
      :busy="isLoadingPolicies"
      :items="policies"
      :fields="fields"
      sort-icon-left
      sort-by="updatedAt"
      sort-desc
      head-variant="white"
      stacked="md"
      thead-class="gl-text-gray-900 border-bottom"
      tbody-class="gl-text-gray-900"
      show-empty
      hover
      selectable
      select-mode="single"
      selected-variant="primary"
      @row-selected="presentPolicyDrawer"
    >
      <template #cell(status)="value">
        <gl-icon
          v-if="value.item.enabled"
          v-gl-tooltip="$options.i18n.statusEnabled"
          :aria-label="$options.i18n.statusEnabled"
          name="check-circle-filled"
          class="gl-text-green-700"
        />
        <span v-else class="gl-sr-only">{{ $options.i18n.statusDisabled }}</span>
      </template>

      <template #cell(environments)="value">
        <policy-environments :environments="value.item.environments" />
      </template>

      <template #cell(updatedAt)="value">
        {{ getTimeAgoString(value.item.updatedAt) }}
      </template>

      <template #empty>
        <slot name="empty-state">
          <gl-empty-state
            ref="tableEmptyState"
            :title="$options.i18n.emptyStateTitle"
            :description="$options.i18n.emptyStateDescription"
            :primary-button-link="documentationFullPath"
            :primary-button-text="$options.i18n.emptyStateButton"
          />
        </slot>
      </template>
    </gl-table>

    <policy-drawer
      :open="hasSelectedPolicy"
      :policy="selectedPolicy"
      :policy-type="policyType"
      :edit-policy-path="editPolicyPath"
      data-testid="policyDrawer"
      @close="deselectPolicy"
    />
  </div>
</template>
