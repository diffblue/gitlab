# frozen_string_literal: true

module EE
  module WikiHelper
    extend ::Gitlab::Utils::Override

    override :wiki_attachment_upload_url
    def wiki_attachment_upload_url
      case @wiki.container
      when Group
        expose_url(api_v4_groups_wikis_attachments_path(id: @wiki.container.id))
      else
        super
      end
    end

    override :wiki_page_render_api_endpoint
    def wiki_page_render_api_endpoint(page)
      return super if page.wiki.is_a?(ProjectWiki)

      expose_path(api_v4_groups_wikis_path(wiki_page_render_api_endpoint_params(page)))
    end
  end
end
