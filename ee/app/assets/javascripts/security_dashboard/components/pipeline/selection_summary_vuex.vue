<script>
import { GlButton, GlFormSelect } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import { __, n__ } from '~/locale';

const REASON_NONE = __('[No reason]');
const REASON_WONT_FIX = __("Won't fix / Accept risk");
const REASON_FALSE_POSITIVE = __('False positive');

export default {
  name: 'SelectionSummary',
  components: {
    GlButton,
    GlFormSelect,
  },
  data() {
    return {
      dismissalReason: null,
    };
  },
  computed: {
    ...mapGetters('vulnerabilities', ['selectedVulnerabilitiesCount']),
    canDismissVulnerability() {
      return this.dismissalReason && this.selectedVulnerabilitiesCount > 0;
    },
    message() {
      return n__(
        'Dismiss %d selected vulnerability as',
        'Dismiss %d selected vulnerabilities as',
        this.selectedVulnerabilitiesCount,
      );
    },
  },
  methods: {
    ...mapActions('vulnerabilities', ['dismissSelectedVulnerabilities']),
    handleDismiss() {
      if (!this.canDismissVulnerability) {
        return;
      }

      if (this.dismissalReason === REASON_NONE) {
        this.dismissSelectedVulnerabilities();
      } else {
        this.dismissSelectedVulnerabilities({ comment: this.dismissalReason });
      }
    },
  },
  dismissalReasons: [
    { value: null, text: __('Select a reason') },
    REASON_FALSE_POSITIVE,
    REASON_WONT_FIX,
    REASON_NONE,
  ],
};
</script>

<template>
  <div class="card">
    <form class="card-body d-flex align-items-center" @submit.prevent="handleDismiss">
      <span data-testid="dismiss-message">{{ message }}</span>
      <gl-form-select
        v-model="dismissalReason"
        class="mx-3 w-auto"
        data-qa-selector="finding_dismissal_reason"
        :options="$options.dismissalReasons"
      />
      <gl-button
        type="submit"
        data-qa-selector="finding_dismiss_button"
        :disabled="!canDismissVulnerability"
      >
        {{ __('Dismiss selected') }}
      </gl-button>
    </form>
  </div>
</template>
