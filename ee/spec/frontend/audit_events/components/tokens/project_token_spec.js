import { shallowMount } from '@vue/test-utils';
import ProjectToken from 'ee/audit_events/components/tokens/project_token.vue';
import AuditFilterToken from 'ee/audit_events/components/tokens/shared/audit_filter_token.vue';
import Api from '~/api';
import { isValidEntityId } from 'ee/audit_events/token_utils';

jest.mock('~/api.js', () => ({
  project: jest.fn().mockResolvedValue({ data: { id: 1 } }),
  projects: jest.fn().mockResolvedValue({ data: [{ id: 1 }, { id: 2 }] }),
}));

jest.mock('ee/audit_events/token_utils', () => ({
  isValidEntityId: jest.fn().mockReturnValue(true),
}));

describe('ProjectToken', () => {
  let wrapper;

  const value = { data: 123 };
  const config = { type: 'foo' };

  const findAuditFilterToken = () => wrapper.findComponent(AuditFilterToken);

  const initComponent = () => {
    wrapper = shallowMount(ProjectToken, {
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
      const id = 123;

      const result = await subject(id);

      expect(result).toEqual({ id: 1 });
      expect(Api.project).toHaveBeenCalledWith(id);
    });

    it('fetchSuggestions', async () => {
      const subject = wrapper.vm.$options.tokenMethods.fetchSuggestions;
      const term = 'term';

      const result = await subject(term);

      expect(result).toEqual([{ id: 1 }, { id: 2 }]);
      expect(Api.projects).toHaveBeenCalledWith(term, { membership: false });
    });

    it('getItemName', () => {
      const subject = wrapper.vm.$options.tokenMethods.getItemName;

      expect(subject({ name: 'foo' })).toBe('foo');
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
