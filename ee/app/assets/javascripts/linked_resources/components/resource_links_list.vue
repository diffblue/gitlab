<script>
import ResourceLinkItem from './resource_links_list_item.vue';

export default {
  name: 'ResourceLinksList',
  components: {
    ResourceLinkItem,
  },
  props: {
    canAdmin: {
      type: Boolean,
      required: false,
      default: false,
    },
    resourceLinks: {
      type: Array,
      required: false,
      default: () => [],
    },
    isFormVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div
    class="related-issues-token-body"
    :class="{
      'gl-border-t': !isFormVisible,
    }"
    data-testid="resource-link-list"
  >
    <ul class="related-items-list content-list gl-p-3!">
      <li
        v-for="link in resourceLinks"
        :key="link.id"
        :data-key="link.id"
        class="list-item gl-py-0! gl-border-0!"
      >
        <resource-link-item
          :id-key="link.id"
          :icon-name="link.linkType"
          :link-text="link.linkText"
          :link-value="link.link"
          :can-remove="canAdmin"
          @removeRequest="$emit('resourceLinkRemoveRequest', $event)"
        />
      </li>
    </ul>
  </div>
</template>
