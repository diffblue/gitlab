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
          this.$toast.show(__('User pipeline minutes were successfully reset.'));
        }
      } catch (e) {
        this.$toast.show(__('There was an error resetting user pipeline minutes.'));
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
    :title="s__('SharedRunnersMinutesSettings|Reset used pipeline minutes')"
    :dismissible="false"
  >
    {{
      s__(
        'SharedRunnersMinutesSettings|By resetting the pipeline minutes for this namespace, the currently used minutes will be set to zero.',
      )
    }}
    <template #actions>
      <gl-button variant="confirm" :loading="loading" @click="resetPipelineMinutes">
        {{ s__('SharedRunnersMinutesSettings|Reset pipeline minutes') }}
      </gl-button>
    </template>
  </gl-alert>
</template>
