<script>
import { GlCollapse, GlButton, GlAlert } from '@gitlab/ui';
import vulnerabilityStateMutations from 'ee/security_dashboard/graphql/mutate_vulnerability_state';
import eventHub from 'ee/security_dashboard/utils/event_hub';
import { __, s__, n__ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import StatusDropdown from './status_dropdown.vue';

export default {
  name: 'SelectionSummary',
  components: {
    GlCollapse,
    GlButton,
    GlAlert,
    StatusDropdown,
  },
  props: {
    selectedVulnerabilities: {
      type: Array,
      required: true,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isSubmitting: false,
      updateErrorText: null,
      selectedStatus: null,
      selectedStatusPayload: undefined,
    };
  },
  computed: {
    selectedVulnerabilitiesCount() {
      return this.selectedVulnerabilities.length;
    },
    shouldShowActionButtons() {
      return Boolean(this.selectedStatus);
    },
  },
  methods: {
    handleStatusDropdownChange({ action, payload }) {
      this.selectedStatus = action;
      this.selectedStatusPayload = payload;
    },

    resetSelected() {
      this.$emit('cancel-selection');
    },

    handleSubmit() {
      this.isSubmitting = true;
      this.updateErrorText = null;
      let fulfilledCount = 0;
      const rejected = [];

      const promises = this.selectedVulnerabilities.map((vulnerability) => {
        return this.$apollo
          .mutate({
            mutation: vulnerabilityStateMutations[this.selectedStatus],
            variables: { id: vulnerability.id, ...this.selectedStatusPayload },
          })
          .then(({ data }) => {
            const [queryName] = Object.keys(data);

            if (data[queryName].errors?.length > 0) {
              throw data[queryName].errors;
            }

            fulfilledCount += 1;
            this.$emit('vulnerability-updated', vulnerability.id);
          })
          .catch(() => {
            rejected.push(vulnerability.id.split('/').pop());
          });
      });

      return Promise.all(promises).then(() => {
        this.isSubmitting = false;

        if (fulfilledCount > 0) {
          toast(this.$options.i18n.statusChanged(this.selectedStatus, fulfilledCount));
          eventHub.$emit('vulnerabilities-updated', this);
        }

        if (rejected.length > 0) {
          this.updateErrorText = this.$options.i18n.vulnerabilitiesUpdateFailed(
            rejected.join(', '),
          );
        }
      });
    },
  },
  i18n: {
    cancel: __('Cancel'),
    selected: __('Selected'),
    changeStatus: s__('SecurityReports|Change status'),
    statusChanged: (status, count) =>
      ({
        confirm: n__(
          '%d vulnerability set to confirmed',
          '%d vulnerabilities set to confirmed',
          count,
        ),
        resolve: n__(
          '%d vulnerability set to resolved',
          '%d vulnerabilities set to resolved',
          count,
        ),
        dismiss: n__(
          '%d vulnerability set to dismissed',
          '%d vulnerabilities set to dismissed',
          count,
        ),
        revert: n__(
          '%d vulnerability set to needs triage',
          '%d vulnerabilities set to needs triage',
          count,
        ),
      }[status]),
    vulnerabilitiesUpdateFailed: (vulnIds) =>
      s__(`SecurityReports|Failed updating vulnerabilities with the following IDs: ${vulnIds}`),
  },
};
</script>

<template>
  <gl-collapse
    :visible="visible"
    class="selection-summary"
    data-testid="selection-summary-collapse"
  >
    <div class="card" :class="{ 'with-error': Boolean(updateErrorText) }">
      <gl-alert v-if="updateErrorText" variant="danger" :dismissible="false">
        {{ updateErrorText }}
      </gl-alert>

      <form class="card-body gl-display-flex gl-align-items-center" @submit.prevent="handleSubmit">
        <div
          class="gl-line-height-0 gl-border-r-solid gl-border-gray-100 gl-pr-6 gl-border-1 gl-h-7 gl-display-flex gl-align-items-center"
        >
          <span
            ><b>{{ selectedVulnerabilitiesCount }}</b> {{ $options.i18n.selected }}</span
          >
        </div>
        <div class="gl-flex-grow-1 gl-ml-6 gl-mr-4">
          <status-dropdown @change="handleStatusDropdownChange" />
        </div>
        <template v-if="shouldShowActionButtons">
          <gl-button type="button" class="gl-mr-4" @click="resetSelected">
            {{ $options.i18n.cancel }}
          </gl-button>
          <gl-button type="submit" category="primary" variant="confirm" :disabled="isSubmitting">
            {{ $options.i18n.changeStatus }}
          </gl-button>
        </template>
      </form>
    </div>
  </gl-collapse>
</template>
