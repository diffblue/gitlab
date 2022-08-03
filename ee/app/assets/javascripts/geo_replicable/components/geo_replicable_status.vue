<script>
import { GlIcon } from '@gitlab/ui';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { STATUS_ICON_NAMES, STATUS_ICON_CLASS, DEFAULT_STATUS } from '../constants';

export default {
  name: 'GeoReplicableStatus',
  components: {
    GlIcon,
  },
  props: {
    status: {
      type: String,
      required: false,
      default: DEFAULT_STATUS,
    },
  },
  computed: {
    capitalizedStatus() {
      return capitalizeFirstCharacter(this.status);
    },
    styleProperties() {
      if (STATUS_ICON_NAMES[this.status] && STATUS_ICON_CLASS[this.status]) {
        return {
          iconName: STATUS_ICON_NAMES[this.status],
          cssClass: STATUS_ICON_CLASS[this.status],
        };
      }

      return {
        iconName: STATUS_ICON_NAMES[DEFAULT_STATUS],
        cssClass: STATUS_ICON_CLASS[DEFAULT_STATUS],
      };
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex align-items-center"
    :class="styleProperties.cssClass"
    data-testid="replicable-item-status"
  >
    <gl-icon :name="styleProperties.iconName" class="gl-mr-2" />
    <span class="gl-font-weight-bold gl-font-sm">{{ capitalizedStatus }}</span>
  </div>
</template>
