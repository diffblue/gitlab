import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ResourceLinksBlock from 'ee_component/linked_resources/components/resource_links_block.vue';

export default function initLinkedResources(featureAvailable = false) {
  const linkedResourcesRootElement = document.querySelector('.js-linked-resources-root');

  if (linkedResourcesRootElement && featureAvailable) {
    const { issuableId, canAddResourceLinks, helpPath } = linkedResourcesRootElement.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: linkedResourcesRootElement,
      name: 'LinkedResourcesRoot',
      components: {
        resourceLinksBlock: ResourceLinksBlock,
      },
      render: (createElement) =>
        createElement('resource-links-block', {
          props: {
            issuableId,
            helpPath,
            canAddResourceLinks: parseBoolean(canAddResourceLinks),
          },
        }),
    });
  }
}
