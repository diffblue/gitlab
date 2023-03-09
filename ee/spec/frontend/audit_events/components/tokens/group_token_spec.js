import { shallowMount } from '@vue/test-utils';
import GroupToken from 'ee/audit_events/components/tokens/group_token.vue';
import AuditFilterToken from 'ee/audit_events/components/tokens/shared/audit_filter_token.vue';
import Api from '~/api';
import { isValidEntityId } from 'ee/audit_events/token_utils';

jest.mock('~/api.js', () => ({
  group: jest.fn().mockResolvedValue({ id: 1 }),
  groups: jest.fn().mockResolvedValue([{ id: 1 }, { id: 2 }]),
}));

jest.mock('ee/audit_events/token_utils', () => ({
  isValidEntityId: jest.fn().mockReturnValue(true),
}));

describe('GroupToken', () => {
  let wrapper;

  const value = { data: 123 };
  const config = { type: 'foo' };

  const findAuditFilterToken = () => wrapper.findComponent(AuditFilterToken);

  const initComponent = () => {
    wrapper = shallowMount(GroupToken, {
      propsData: {
        value,
        config,
        active: false,
        cursorPosition: 'start',
      },
      stubs: { AuditFilterToken },
    });
  };

  beforeEach(() => {
    initComponent();
  });

  it('binds to value, config and token methods to the filter token', () => {
    expect(findAuditFilterToken().props()).toMatchObject({
      value,
      config,
      ...wrapper.vm.$options.tokenMethods,
    });
  });

  describe('tokenMethods', () => {
    it('fetchItem', async () => {
      const subject = wrapper.vm.$options.tokenMethods.fetchItem;
      const term = 'term';

      const result = await subject(term);

      expect(result).toEqual({ id: 1 });
      expect(Api.group).toHaveBeenCalledWith(term);
    });

    it('fetchSuggestions', async () => {
      const subject = wrapper.vm.$options.tokenMethods.fetchSuggestions;
      const term = 'term';

      const result = await subject(term);

      expect(result).toEqual([{ id: 1 }, { id: 2 }]);
      expect(Api.groups).toHaveBeenCalledWith(term);
    });

    it('getItemName', () => {
      const subject = wrapper.vm.$options.tokenMethods.getItemName;

      expect(subject({ full_name: 'foo' })).toBe('foo');
    });

    it('getSuggestionValue', () => {
      const subject = wrapper.vm.$options.tokenMethods.getSuggestionValue;
      const id = 123;

      expect(subject({ id })).toBe('123');
    });

    it('isValidIdentifier', () => {
      const subject = wrapper.vm.$options.tokenMethods.isValidIdentifier;

      expect(subject('foo')).toBe(true);
      expect(isValidEntityId).toHaveBeenCalledWith('foo');
    });

    it('findActiveItem', () => {
      const subject = wrapper.vm.$options.tokenMethods.findActiveItem;
      const suggestions = [
        { id: 1, username: 'foo' },
        { id: 2, username: 'bar' },
      ];

      expect(subject(suggestions, 1)).toBe(suggestions[0]);
    });
  });
});
