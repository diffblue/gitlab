<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { __ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  inject: {
    resetMinutesPath: {
      default: '',
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async resetPipelineMinutes() {
      this.loading = true;
      try {
        const response = await axios.post(this.resetMinutesPath);
        if (response.status === HTTP_STATUS_OK) {
          this.$toast.show(__('Successfully reset compute usage for namespace.'));
        }
      } catch (e) {
        this.$toast.show(__('An error occurred while resetting the compute usage.'));
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>
<template>
  <gl-alert
    class="gl-mb-5"
    variant="info"
    :title="s__('SharedRunnersMinutesSettings|Reset compute usage')"
    :dismissible="false"
  >
    {{
      s__(
        'SharedRunnersMinutesSettings|When you reset the compute usage for this namespace, the compute usage changes to zero.',
      )
    }}
    <template #actions>
      <gl-button variant="confirm" :loading="loading" @click="resetPipelineMinutes">
        {{ s__('SharedRunnersMinutesSettings|Reset compute usage') }}
      </gl-button>
    </template>
  </gl-alert>
</template>
