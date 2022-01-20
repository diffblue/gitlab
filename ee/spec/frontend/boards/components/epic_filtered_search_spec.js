import { shallowMount } from '@vue/test-utils';
import { orderBy } from 'lodash';
import EpicFilteredSearch from 'ee/boards/components/epic_filtered_search.vue';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import { __ } from '~/locale';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

describe('EpicFilteredSearch', () => {
  let wrapper;
  const { fetchAuthors, fetchLabels } = issueBoardFilters({}, '', 'group');

  const createComponent = ({ initialFilterParams = {} } = {}) => {
    wrapper = shallowMount(EpicFilteredSearch, {
      provide: { initialFilterParams },
      props: {
        fullPath: '',
        boardType: '',
      },
    });
  };

  window.gon = {
    current_user_id: '4',
    current_username: 'root',
    current_user_avatar_url: 'url',
    current_user_fullname: 'Admin',
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(wrapper.findComponent(BoardFilteredSearch).exists()).toBe(true);
    });

    it('passes tokens to BoardFilteredSearch', () => {
      const tokens = [
        {
          icon: 'labels',
          title: __('Label'),
          type: 'label',
          operators: [
            { value: '=', description: 'is' },
            { value: '!=', description: 'is not' },
          ],
          token: LabelToken,
          unique: false,
          symbol: '~',
          fetchLabels,
        },
        {
          icon: 'pencil',
          title: __('Author'),
          type: 'author',
          operators: [
            { value: '=', description: 'is' },
            { value: '!=', description: 'is not' },
          ],
          symbol: '@',
          token: AuthorToken,
          unique: true,
          fetchAuthors,
          preloadedAuthors: [
            { id: 'gid://gitlab/User/4', name: 'Admin', username: 'root', avatarUrl: 'url' },
          ],
        },
      ];
      expect(wrapper.findComponent(BoardFilteredSearch).props('tokens').toString()).toBe(
        orderBy(tokens, ['title']).toString(),
      );
    });
  });
});
