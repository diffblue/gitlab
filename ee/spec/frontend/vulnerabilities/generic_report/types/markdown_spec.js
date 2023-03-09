import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Markdown from 'ee/vulnerabilities/components/generic_report/types/markdown.vue';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const MARKDOWN_PATH = '/api/:version/markdown';

// Original markdown
const MARKDOWN = 'Checkout [GitLab](http://gitlab.com) "><script>alert(1)</script>';
// HTML returned from /api/v4/markdown
const RENDERED_MARKDOWN =
  '\u003cp data-sourcepos="1:1-1:79" dir="auto"\u003eCheckout \u003ca href="http://gitlab.com"\u003eGitLab\u003c/a\u003e Hello! Welcome "\u0026gt;\u003c/p\u003e';
// HTML with v-safe-html
const HTML_SAFE_RENDERED_MARKDOWN =
  '\u003cp dir="auto" data-sourcepos="1:1-1:79"\u003eCheckout \u003ca href="http://gitlab.com"\u003eGitLab\u003c/a\u003e Hello! Welcome "\u0026gt;\u003c/p\u003e';

describe('ee/vulnerabilities/components/generic_report/types/markdown.vue', () => {
  let wrapper;
  let mock;

  const createWrapper = () => {
    return shallowMount(Markdown, {
      propsData: {
        value: MARKDOWN,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findMarkdown = () => wrapper.find('[data-testid="markdown"]');

  const setUpMockMarkdown = () => {
    const url = buildApiUrl(MARKDOWN_PATH);
    mock
      .onPost(url, {
        text: MARKDOWN,
        gfm: true,
      })
      .replyOnce(HTTP_STATUS_OK, { html: RENDERED_MARKDOWN });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    setUpMockMarkdown();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('when loading', () => {
    it('shows the loading icon', () => {
      wrapper = createWrapper();

      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    it('shows markdown', async () => {
      wrapper = createWrapper();

      await axios.waitForAll();
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findMarkdown().element.innerHTML).toBe(HTML_SAFE_RENDERED_MARKDOWN);
    });
  });
});
