import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearch } from '@gitlab/ui';
import GroupDependenciesFilteredSearch from 'ee/dependencies/components/filtered_search/group_dependencies_filtered_search.vue';

describe('GroupDependenciesFilteredSearch', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GroupDependenciesFilteredSearch);
  };

  beforeEach(createComponent);

  it('contains a filtered-search input', () => {
    expect(wrapper.findComponent(GlFilteredSearch).props()).toMatchObject({
      availableTokens: [],
      placeholder: 'Search or filter dependencies...',
    });
  });
});
