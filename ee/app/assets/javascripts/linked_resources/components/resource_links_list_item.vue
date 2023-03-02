<script>
import { GlIcon, GlButton, GlTooltipDirective, GlLink } from '@gitlab/ui';
import api from '~/api';
import '~/commons/bootstrap';
import { resourceLinksListI18n } from '../constants';
import { getLinkIcon } from './utils';

export default {
  name: 'ResourceLinkItem',
  components: {
    GlIcon,
    GlButton,
    GlLink,
  },
  i18n: resourceLinksListI18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    idKey: {
      type: String,
      required: false,
      default: '',
    },
    iconName: {
      type: String,
      required: false,
      default: 'external-link',
    },
    linkText: {
      type: String,
      required: false,
      default: '',
    },
    linkValue: {
      type: String,
      required: false,
      default: '',
    },
    canRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isRemoveDisabled: false,
    };
  },
  computed: {
    iconClasses() {
      return `ic-${this.iconName}`;
    },
  },
  methods: {
    getLinkIcon,
    trackResourceLinkClick() {
      api.trackRedisHllUserEvent('incident_management_issuable_resource_link_visited');
    },
    handleRemove() {
      this.isRemoveDisabled = true;
      this.$emit('removeRequest', this.idKey);
    },
  },
};
</script>

<template>
  <div
    :class="{
      'gl-pr-2': canRemove,
    }"
    class="item-body d-flex align-items-center gl-px-3"
  >
    <div
      class="item-contents gl-display-flex gl-align-items-center gl-flex-wrap gl-flex-grow-1 flex-xl-nowrap gl-min-h-7"
    >
      <div class="item-title d-flex align-items-xl-center mb-xl-0 gl-min-w-0">
        <gl-icon
          class="gl-mr-3 gl-text-gray-500"
          :name="getLinkIcon(iconName)"
          :class="iconClasses"
        />
        <gl-link
          :href="linkValue"
          target="_blank"
          class="sortable-link gl-font-weight-normal"
          @click="trackResourceLinkClick"
          >{{ linkText }}</gl-link
        >
      </div>
    </div>
    <gl-button
      v-if="canRemove"
      v-gl-tooltip
      icon="close"
      category="tertiary"
      size="small"
      :disabled="isRemoveDisabled"
      class="js-issue-item-remove-button gl-ml-5"
      :title="$options.i18n.linkRemoveText"
      :aria-label="$options.i18n.linkRemoveText"
      @click="handleRemove"
    />
  </div>
</template>
