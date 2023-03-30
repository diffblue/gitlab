<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlButton, GlLoadingIcon, GlIcon, GlPopover } from '@gitlab/ui';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import { s__ } from '~/locale';
import PaginatedList from '~/vue_shared/components/paginated_list.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LicenseApprovals from 'ee/approvals/components/license_compliance/index.vue';
import AddLicenseForm from './components/add_license_form.vue';
import AdminLicenseManagementRow from './components/admin_license_management_row.vue';
import DeleteConfirmationModal from './components/delete_confirmation_modal.vue';
import LicenseManagementRow from './components/license_management_row.vue';

export default {
  name: 'LicenseManagement',
  components: {
    AddLicenseForm,
    DeleteConfirmationModal,
    AdminLicenseManagementRow,
    LicenseManagementRow,
    GlButton,
    GlLoadingIcon,
    GlIcon,
    GlPopover,
    PaginatedList,
    LicenseApprovals,
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      formIsOpen: false,
    };
  },
  computed: {
    ...mapState(LICENSE_MANAGEMENT, [
      'managedLicenses',
      'isLoadingManagedLicenses',
      'isAdmin',
      'knownLicenses',
    ]),
    ...mapGetters(LICENSE_MANAGEMENT, [
      'isLicenseBeingUpdated',
      'hasPendingLicenses',
      'isAddingNewLicense',
    ]),
    showLoadingSpinner() {
      return this.isLoadingManagedLicenses && !this.hasPendingLicenses;
    },
  },
  watch: {
    isAddingNewLicense(isAddingNewLicense) {
      if (!isAddingNewLicense) {
        this.closeAddLicenseForm();
      }
    },
  },
  mounted() {
    this.fetchManagedLicenses();
  },
  methods: {
    ...mapActions(LICENSE_MANAGEMENT, ['fetchManagedLicenses', 'setLicenseApproval']),
    openAddLicenseForm() {
      this.formIsOpen = true;
    },
    closeAddLicenseForm() {
      this.formIsOpen = false;
    },
  },
  emptyMessage: s__('LicenseCompliance|There are currently no policies in this project.'),
  emptySearchMessage: s__(
    'LicenseCompliance|There are currently no policies that match in this project.',
  ),
};
</script>
<template>
  <gl-loading-icon v-if="showLoadingSpinner" size="sm" />
  <div v-else class="license-management">
    <delete-confirmation-modal v-if="isAdmin" />

    <paginated-list
      :list="managedLicenses"
      :empty-search-message="$options.emptySearchMessage"
      :empty-message="$options.emptyMessage"
      :filterable="isAdmin"
      filter="name"
      data-qa-selector="license_compliance_list"
    >
      <template #header>
        <div v-if="isAdmin" class="order-1 gl-display-flex gl-align-items-center">
          <gl-button
            class="js-open-form"
            :disabled="formIsOpen"
            variant="confirm"
            data-qa-selector="license_add_button"
            @click="openAddLicenseForm"
          >
            {{ s__('LicenseCompliance|Add license policy') }}
          </gl-button>

          <license-approvals class="gl-ml-3" />
        </div>

        <template v-else>
          <div class="table-section gl-display-flex gl-pl-2 section-70" role="rowheader">
            {{ s__('Licenses|Policy') }}
            <gl-icon
              ref="reportInfo"
              name="question-o"
              class="text-info gl-ml-2 gl-cursor-pointer"
              :aria-label="__('help')"
              :size="14"
            />
            <gl-popover
              :target="() => $refs.reportInfo.$el"
              placement="bottom"
              triggers="click blur"
              :css-classes="['gl-mt-3']"
            >
              <div class="h5">{{ __('Allowed') }}</div>
              <span class="text-secondary">
                {{ s__('Licenses|Acceptable license to be used in the project') }}</span
              >
              <div class="h5">{{ __('Denied') }}</div>
              <span class="text-secondary">
                {{
                  s__(
                    "Licenses|Unacceptable license, if detected it will disallow a merge request until it's removed",
                  )
                }}</span
              >
            </gl-popover>
          </div>

          <div class="table-section section-30" role="rowheader">
            {{ s__('Licenses|Name') }}
          </div>
        </template>
      </template>

      <template v-if="isAdmin" #subheader>
        <div v-if="formIsOpen" class="gl-mt-3 gl-mb-3">
          <add-license-form
            :managed-licenses="managedLicenses"
            :known-licenses="knownLicenses"
            :loading="isAddingNewLicense"
            @addLicense="setLicenseApproval"
            @closeForm="closeAddLicenseForm"
          />
        </div>
      </template>

      <template #default="{ listItem }">
        <admin-license-management-row
          v-if="isAdmin"
          :license="listItem"
          :loading="isLicenseBeingUpdated(listItem.id)"
        />
        <license-management-row v-else :license="listItem" />
      </template>
    </paginated-list>
  </div>
</template>
