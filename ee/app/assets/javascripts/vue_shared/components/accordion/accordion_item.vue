<script>
import { GlSkeletonLoader, GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';

import accordionEventBus from './accordion_event_bus';

const accordionItemUniqueId = (name) => uniqueId(`gl-accordion-item-${name}-`);

export default {
  components: {
    GlSkeletonLoader,
    GlIcon,
  },
  props: {
    accordionId: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    maxHeight: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isExpanded: false,
    };
  },
  computed: {
    contentStyles() {
      return {
        maxHeight: this.maxHeight,
        overflow: 'auto',
      };
    },
    isDisabled() {
      return this.disabled || !this.hasContent;
    },
    hasContent() {
      return this.$scopedSlots.default !== undefined;
    },
  },
  created() {
    this.buttonId = accordionItemUniqueId('trigger');
    this.contentContainerId = accordionItemUniqueId('content-container');
    // create a unique event name so multiple accordion instances don't close each other items
    this.closeOtherItemsEvent = `${this.accordionId}.closeOtherAccordionItems`;

    accordionEventBus.$on(this.closeOtherItemsEvent, this.onCloseOtherAccordionItems);
  },
  destroyed() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    accordionEventBus.$off(this.closeOtherItemsEvent);
  },
  methods: {
    onCloseOtherAccordionItems(trigger) {
      if (trigger !== this) {
        this.collapse();
      }
    },
    handleClick() {
      if (this.isExpanded) {
        this.collapse();
      } else {
        this.expand();
      }
      accordionEventBus.$emit(this.closeOtherItemsEvent, this);
    },
    expand() {
      this.isExpanded = true;
    },
    collapse() {
      this.isExpanded = false;
    },
  },
};
</script>

<template>
  <li class="list-group-item p-0">
    <template v-if="!isLoading">
      <div class="d-flex align-items-stretch">
        <button
          :id="buttonId"
          data-testid="expansion-trigger"
          type="button"
          :disabled="isDisabled"
          :aria-expanded="isExpanded"
          :aria-controls="contentContainerId"
          class="gl-bg-transparent border-0 rounded-0 w-100 p-0 text-left"
          :class="{ 'cursor-default': isDisabled, 'list-group-item-action': !isDisabled }"
          @click="handleClick"
        >
          <div class="d-flex align-items-center p-2">
            <gl-icon
              :size="16"
              class="gl-mr-3 gl-text-gray-900"
              :name="isExpanded ? 'chevron-lg-down' : 'chevron-lg-right'"
            />
            <span
              ><slot name="title" :is-expanded="isExpanded" :is-disabled="isDisabled"></slot
            ></span>
          </div>
        </button>
      </div>
      <section
        v-show="isExpanded"
        :id="contentContainerId"
        data-testid="content-container"
        :aria-labelledby="buttonId"
      >
        <slot name="sub-title"></slot>
        <div data-testid="content" :style="contentStyles"><slot name="default"></slot></div>
      </section>
    </template>
    <div v-else data-testid="loading-indicator" class="d-flex p-2">
      <div class="h-32-px">
        <gl-skeleton-loader :height="32">
          <rect width="12" height="16" rx="4" x="0" y="8" />
          <circle cx="37" cy="15" r="15" />
          <rect width="20" height="16" rx="4" x="63" y="8" />
        </gl-skeleton-loader>
      </div>
    </div>
  </li>
</template>
