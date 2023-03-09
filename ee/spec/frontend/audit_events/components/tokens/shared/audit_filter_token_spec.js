import { nextTick } from 'vue';
import { GlLoadingIcon, GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import AuditFilterToken from 'ee/audit_events/components/tokens/shared/audit_filter_token.vue';
import { createAlert } from '~/alert';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('AuditFilterToken', () => {
  let wrapper;
  const mockItem = { id: 777, name: 'An item name', avatar_url: 'http://item' };
  const mockSuggestions = [
    {
      id: 888,
      name: 'A suggestion name',
      avatar_url: 'http://suggestion',
      full_name: 'Full name',
    },
  ];
  const mockResponseFailed = { response: { status: HTTP_STATUS_NOT_FOUND } };
  const mockFetchLoading = () => new Promise(() => {});

  const findFilteredSearchSuggestions = () => wrapper.findAllByTestId('audit-filter-suggestion');
  const findFilteredSearchToken = () => wrapper.find('#filtered-search-token');
  const findItemAvatar = () => wrapper.findByTestId('audit-filter-item-avatar');
  const findLoadingIcon = (type) => wrapper.find(type).findComponent(GlLoadingIcon);
  const findViewLoadingIcon = () => findLoadingIcon('.view');
  const findSuggestionsLoadingIcon = () => findLoadingIcon('.suggestions');

  const tokenMethods = {
    fetchItem: jest.fn().mockResolvedValue(mockItem),
    fetchSuggestions: jest.fn().mockResolvedValue(mockSuggestions),
    getItemName: jest.fn().mockImplementation((item) => item.name),
    findActiveItem: jest.fn(),
    getSuggestionValue: jest.fn().mockImplementation((item) => item.id),
    isValidIdentifier: jest.fn().mockImplementation((id) => Boolean(id)),
  };

  const initComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(AuditFilterToken, {
        propsData: {
          value: {},
          config: {
            type: 'foo_bar',
          },
          active: false,
          ...tokenMethods,
          ...props,
        },
        stubs: {
          GlFilteredSearchToken: {
            template: `<div id="filtered-search-token">
            <div class="view"><slot name="view"></slot></div>
            <div class="suggestions"><slot name="suggestions"></slot></div>
          </div>`,
          },
        },
      }),
    );
  };

  it('passes the config correctly', () => {
    const config = {
      icon: 'user',
      type: 'user',
      title: 'User',
      unique: true,
    };
    initComponent({ config });

    expect(findFilteredSearchToken().props('config')).toEqual(config);
  });

  describe('when initialized with a value', () => {
    const value = { data: 999 };

    beforeEach(() => {
      initComponent({ value });
    });

    it('passes the value correctly', () => {
      expect(findFilteredSearchToken().props('value')).toEqual(value);
    });

    it('checks if the token has a valid identifier', () => {
      expect(tokenMethods.isValidIdentifier).toHaveBeenCalledWith(value.data);
    });

    it('fetches an item to display', () => {
      expect(tokenMethods.fetchItem).toHaveBeenCalledWith(value.data);
    });

    describe('when fetching an item', () => {
      it('shows only the view loading icon', async () => {
        initComponent({ value, fetchItem: mockFetchLoading });

        await nextTick();

        expect(findViewLoadingIcon().exists()).toBe(true);
        expect(findSuggestionsLoadingIcon().exists()).toBe(false);
      });
    });

    describe('when fetching the item succeeded', () => {
      beforeEach(() => {
        const fetchItem = jest.fn().mockResolvedValue(mockItem);
        initComponent({ value, fetchItem });
      });

      it('does not show the view loading icon', () => {
        expect(findViewLoadingIcon().exists()).toBe(false);
      });

      it('renders the active item avatar', () => {
        expect(findItemAvatar().props()).toMatchObject({
          alt: `${mockItem.name}'s avatar`,
          entityId: mockItem.id,
          src: mockItem.avatar_url,
          size: 16,
        });
      });

      it('sets the suggestions to the fetched item', () => {
        expect(findFilteredSearchSuggestions()).toHaveLength(1);
        expect(findFilteredSearchSuggestions().at(0).props('value')).toBe(mockItem.id);
      });
    });

    describe('when fetching the item failed', () => {
      beforeEach(() => {
        const fetchItem = jest.fn().mockRejectedValue(mockResponseFailed);
        initComponent({ value, fetchItem });
      });

      it('shows an alert error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to find foo bar. Please search for another foo bar.',
        });
      });
    });
  });

  describe('when initialized without a value', () => {
    beforeEach(() => {
      initComponent();
    });

    it('fetches suggestions to display', () => {
      expect(tokenMethods.fetchSuggestions).toHaveBeenCalled();
    });

    describe('when fetching suggestions', () => {
      it('shows only the suggestions loading icon', async () => {
        initComponent({ fetchSuggestions: mockFetchLoading });

        await nextTick();

        expect(findSuggestionsLoadingIcon().exists()).toBe(true);
        expect(findViewLoadingIcon().exists()).toBe(false);
      });
    });

    describe('when fetching the suggestions succeeded', () => {
      beforeEach(() => {
        const fetchSuggestions = jest.fn().mockResolvedValue(mockSuggestions);
        initComponent({ fetchSuggestions });
      });

      it('does not show the suggestions loading icon', () => {
        expect(findSuggestionsLoadingIcon().exists()).toBe(false);
      });

      it('gets the suggestion value', () => {
        expect(tokenMethods.getSuggestionValue).toHaveBeenCalled();
      });

      it('renders the suggestions', () => {
        expect(findFilteredSearchSuggestions()).toHaveLength(mockSuggestions.length);
      });

      it('renders an avatar for each suggestion', () => {
        mockSuggestions.forEach((suggestion, index) => {
          const avatar = findFilteredSearchSuggestions().at(index).findComponent(GlAvatar);

          expect(avatar.props()).toMatchObject({
            alt: `${suggestion.name}'s avatar`,
            entityId: suggestion.id,
            src: suggestion.avatar_url,
            size: 32,
          });
        });
      });
    });

    describe('when fetching the suggestions failed', () => {
      it('shows an alert error message', async () => {
        const fetchSuggestions = jest.fn().mockRejectedValue(mockResponseFailed);
        initComponent({ fetchSuggestions });

        await nextTick();
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to find foo bar. Please search for another foo bar.',
        });
      });
    });
  });

  describe('when no suggestion could be found', () => {
    it('renders an empty message', () => {
      const fetchSuggestions = jest.fn().mockResolvedValue([]);
      initComponent({ fetchSuggestions });

      expect(wrapper.text()).toBe('No matching foo bar found.');
    });
  });

  describe('when a view item could not be found', () => {
    it('does not render an item avatar', () => {
      const value = { data: 1 };
      const fetchItem = jest.fn().mockResolvedValue(undefined);
      initComponent({ value, fetchItem });

      expect(findItemAvatar().exists()).toBe(false);
    });
  });
});
