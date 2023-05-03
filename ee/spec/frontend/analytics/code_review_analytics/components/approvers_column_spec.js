import { GlAvatarLink, GlAvatarsInline } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApproversColumn from 'ee/analytics/code_review_analytics/components/approvers_column.vue';

describe('ApproversColumn component', () => {
  let wrapper;

  const approvers = [
    {
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      web_url: 'http://127.0.0.1:3000/root',
      name: 'Administrator',
      username: 'root',
    },
    {
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      web_url: 'http://127.0.0.1:3000/desiree',
      name: 'Sharla Beier',
      username: 'desiree',
    },
    {
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      web_url: 'http://127.0.0.1:3000/nina',
      name: 'Cory Eichmann',
      username: 'nina',
    },
    {
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      web_url: 'http://127.0.0.1:3000/shamika',
      name: 'Melaine Gibson',
      username: 'shamika',
    },
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApproversColumn, {
      propsData: {
        ...props,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatarLink);
  const findInlineAvatars = () => wrapper.findComponent(GlAvatarsInline);

  describe('when an empty list approvers is passed', () => {
    beforeEach(() => {
      createComponent({ approvers: [] });
    });

    it('renders a dash', () => {
      expect(wrapper.text()).toContain('–');
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when a list with one approver is passed', () => {
    beforeEach(() => {
      createComponent({ approvers: [approvers[0]] });
    });

    it('renders the GlAvatarLink component', () => {
      expect(findAvatar().exists()).toBe(true);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe.each`
    totalApprovers       | data                     | maxVisible
    ${'two'}             | ${approvers.slice(0, 2)} | ${3}
    ${'three'}           | ${approvers.slice(0, 3)} | ${3}
    ${'more than three'} | ${approvers}             | ${2}
  `('when a list with $totalApprovers approvers is passed', ({ data, maxVisible }) => {
    beforeEach(() => {
      createComponent({ approvers: data });
    });

    it('renders a GlAvatarsInline component', () => {
      expect(findInlineAvatars().exists()).toBe(true);
    });

    it(`sets collapsed to true`, () => {
      expect(findInlineAvatars().props('collapsed')).toBe(true);
    });

    it(`returns maxVisible to be ${maxVisible}`, () => {
      expect(wrapper.vm.maxVisible).toBe(maxVisible);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
