<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlModal,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ScanTypeBadge from 'ee/security_configuration/dast_profiles/components/dast_scan_type_badge.vue';
import PreScanVerificationConfigurator from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_configurator.vue';
import dastProfileRunMutation from '../../graphql/dast_profile_run.mutation.graphql';
import dastProfileDelete from '../../graphql/dast_profile_delete.mutation.graphql';
import handlesErrors from '../../mixins/handles_errors';
import { removeProfile } from '../../graphql/cache_utils';
import dastProfilesQuery from '../../graphql/dast_profiles.query.graphql';
import { SAVED_TAB_TABLE_FIELDS, LEARN_MORE_TEXT, MAX_DAST_PROFILES_COUNT } from '../../constants';
import BaseTab from './base_tab.vue';

export default {
  query: dastProfilesQuery,
  components: {
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlIcon,
    GlModal,
    BaseTab,
    PreScanVerificationConfigurator,
    ScanTypeBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [handlesErrors, glFeatureFlagMixin()],
  inject: ['canEditOnDemandScans', 'projectPath'],
  maxItemsCount: MAX_DAST_PROFILES_COUNT,
  tableFields: SAVED_TAB_TABLE_FIELDS,
  deleteScanModalId: `delete-scan-modal`,
  i18n: {
    title: s__('OnDemandScans|Scan library'),
    emptyStateTitle: s__('OnDemandScans|There are no saved scans.'),
    emptyStateText: LEARN_MORE_TEXT,
    actions: __('Actions'),
    moreActions: __('More actions'),
    runScan: s__('OnDemandScans|Run scan'),
    runScanError: s__('OnDemandScans|Could not run the scan. Please try again.'),
    editProfile: s__('OnDemandScans|Edit profile'),
    editButtonLabel: __('Edit'),
    deleteModalTitle: s__('OnDemandScans|Are you sure you want to delete this scan?'),
    deleteButtonLabel: __('Delete'),
    deleteProfile: s__('OnDemandScans|Delete profile'),
    deletionError: s__(
      'OnDemandScans|Could not delete saved scan. Please refresh the page, or try again later.',
    ),
    verifyConfigurationLabel: s__('OnDemandScans|Verify configuration'),
  },
  data() {
    return {
      runningScanId: null,
      deletingScanId: null,
    };
  },
  methods: {
    async runScan({ id }) {
      this.resetActionError();
      this.runningScanId = id;

      try {
        const {
          data: {
            dastProfileRun: { pipelineUrl, errors },
          },
        } = await this.$apollo.mutate({
          mutation: dastProfileRunMutation,
          variables: {
            input: {
              id,
            },
          },
        });

        if (errors.length) {
          this.handleActionError(errors[0]);
          this.runningScanId = null;
        } else {
          redirectTo(pipelineUrl); // eslint-disable-line import/no-deprecated
        }
      } catch (exception) {
        this.handleActionError(this.$options.i18n.runScanError, exception);
        this.runningScanId = null;
      }
    },
    prepareProfileDeletion(profileId) {
      this.deletingScanId = profileId;
      this.$refs[this.$options.deleteScanModalId].show();
    },
    async deleteProfile() {
      this.resetActionError();

      try {
        await this.$apollo.mutate({
          mutation: dastProfileDelete,
          variables: {
            input: {
              id: this.deletingScanId,
            },
          },
          update: (store, { data = {} }) => {
            const errors = data.dastProfileDelete?.errors ?? [];

            if (errors.length) {
              this.handleActionError(errors[0]);
            } else {
              removeProfile({
                profileId: this.deletingScanId,
                store,
                queryBody: {
                  query: dastProfilesQuery,
                  variables: {
                    fullPath: this.projectPath,
                  },
                },
              });
            }
          },
          optimisticResponse: {
            // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
            // eslint-disable-next-line @gitlab/require-i18n-strings
            __typename: 'Mutation',
            dastProfileDelete: {
              __typename: 'DastProfileDeletePayload',
              errors: [],
            },
          },
        });
      } catch (exception) {
        this.handleActionError(this.$options.i18n.deletionError, exception);
      }
    },
    cancelDeletion() {
      this.deletingScanId = null;
    },
    openSidebar() {
      this.$refs.verification.openSidebar();
    },
    actionDisclosureItemsConfig(item) {
      const actionItems = [
        {
          href: item.editPath,
          text: this.$options.i18n.editButtonLabel,
          extraAttrs: {
            'aria-label': this.$options.i18n.editProfile,
            'data-testid': 'edit-scan-button-desktop',
          },
        },
        {
          text: this.$options.i18n.deleteButtonLabel,
          action: () => this.prepareProfileDeletion(item.id),
          extraAttrs: {
            'aria-label': this.$options.i18n.deleteProfile,
            'data-testid': 'delete-scan-button-desktop',
            class: 'gl-text-red-500!',
            boundary: 'viewport',
            variant: 'danger',
          },
        },
      ];

      if (this.glFeatures.dastPreScanVerification) {
        actionItems.splice(1, 0, {
          text: this.$options.i18n.verifyConfigurationLabel,
          action: () => this.openSidebar(),
          extraAttrs: {
            'aria-label': this.$options.i18n.verifyConfigurationLabel,
            'data-testid': 'verify-scan-button-desktop',
          },
        });
      }

      return actionItems;
    },
  },
};
</script>

<template>
  <base-tab
    :max-items-count="$options.maxItemsCount"
    :query="$options.query"
    :query-variables="$options.queryVariables"
    :title="$options.i18n.title"
    :fields="$options.tableFields"
    :empty-state-title="$options.i18n.emptyStateTitle"
    :empty-state-text="$options.i18n.emptyStateText"
    v-bind="$attrs"
  >
    <template v-if="hasActionError" #error>
      {{ actionErrorMessage }}
    </template>

    <template #after-name="item"><gl-icon name="branch" /> {{ item.branch.name }}</template>

    <template #cell(scanType)="{ value }">
      <scan-type-badge :scan-type="value" />
    </template>

    <template #cell(actions)="{ item }">
      <div
        v-if="canEditOnDemandScans"
        data-testid="saved-scanners-actions"
        class="gl-md-w-full gl-text-right"
      >
        <gl-button
          size="small"
          data-testid="dast-scan-run-button"
          :loading="runningScanId === item.id"
          :disabled="Boolean(runningScanId)"
          @click="runScan(item)"
        >
          {{ $options.i18n.runScan }}
        </gl-button>

        <!-- More actions for desktop -->
        <gl-disclosure-dropdown
          v-gl-tooltip="{ delay: { show: 700, hide: 200 } }"
          text-sr-only
          no-caret
          right
          category="tertiary"
          size="small"
          icon="ellipsis_v"
          class="gl-display-none gl-md-display-inline-flex!"
          toggle-class="gl-border-0! gl-shadow-none!"
          :toggle-text="$options.i18n.moreActions"
          :title="$options.i18n.moreActions"
        >
          <gl-disclosure-dropdown-item
            v-for="disclosureItem in actionDisclosureItemsConfig(item)"
            :key="disclosureItem.text"
            :item="disclosureItem"
          />
        </gl-disclosure-dropdown>

        <!-- More actions for mobile -->
        <gl-button
          :href="item.editPath"
          :aria-label="$options.i18n.editProfile"
          category="tertiary"
          class="gl-md-display-none"
          size="small"
          data-testid="edit-scan-button-mobile"
        >
          {{ $options.i18n.editButtonLabel }}
        </gl-button>
        <gl-button
          v-if="glFeatures.dastPreScanVerification"
          :aria-label="$options.i18n.verifyConfigurationLabel"
          category="tertiary"
          class="gl-md-display-none"
          icon="review-checkmark"
          data-testid="verify-scan-button-mobile"
          size="small"
          @click="openSidebar"
        />
        <gl-button
          category="tertiary"
          icon="remove"
          variant="danger"
          size="small"
          class="gl-md-display-none"
          data-testid="delete-scan-button-mobile"
          :aria-label="$options.i18n.deleteProfile"
          @click="prepareProfileDeletion(item.id)"
        />
      </div>
    </template>

    <gl-modal
      :ref="$options.deleteScanModalId"
      :modal-id="$options.deleteScanModalId"
      :title="$options.i18n.deleteModalTitle"
      :ok-title="$options.i18n.deleteButtonLabel"
      ok-variant="danger"
      body-class="gl-display-none"
      lazy
      @ok="deleteProfile"
      @cancel="cancelDeletion"
    />

    <pre-scan-verification-configurator
      v-if="glFeatures.dastPreScanVerification"
      ref="verification"
      :show-trigger="false"
    />
  </base-tab>
</template>
