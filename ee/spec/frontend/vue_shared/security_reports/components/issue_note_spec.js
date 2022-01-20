import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import component from 'ee/vue_shared/security_reports/components/issue_note.vue';

describe('Issue note', () => {
  const now = new Date();
  const feedback = {
    author: {
      name: 'Tanuki',
      username: 'gitlab',
    },
    issue_url: '/path-to-the-issue',
    issue_iid: 1,
    created_at: now.toString(),
  };
  const project = {
    value: 'Project one',
    url: '/path-to-the-project',
  };

  describe('with no attached project', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(component, {
        stubs: { GlSprintf },
        propsData: { feedback },
      });
    });

    it('should pass the author to the event item', () => {
      expect(wrapper.findComponent(EventItem).props('author')).toBe(feedback.author);
    });

    it('should pass the created date to the event item', () => {
      expect(wrapper.findComponent(EventItem).props('createdAt')).toBe(feedback.created_at);
    });

    it('should return the event text with no project data', () => {
      expect(wrapper.text()).toBe(`Created issue #${feedback.issue_iid}`);
    });
  });

  describe('with an attached project', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(component, {
        stubs: { GlSprintf },
        propsData: { feedback, project },
      });
    });

    it('should return the event text with project data', () => {
      expect(wrapper.text()).toBe(`Created issue #${feedback.issue_iid} at ${project.value}`);
    });
  });

  describe('with unsafe data', () => {
    let wrapper;
    const unsafeProject = {
      ...project,
      value: 'Foo <script>alert("XSS")</script>',
    };

    beforeEach(() => {
      wrapper = shallowMount(component, {
        stubs: { GlSprintf },
        propsData: {
          feedback,
          project: unsafeProject,
        },
      });
    });

    it('should escape the project name', () => {
      // Test that the XSS text has been rendered literally as safe text.
      expect(wrapper.text()).toContain(unsafeProject.value);
    });
  });
});
