# frozen_string_literal: true

module Gitlab
  module Geo
    module GeoTasks
      extend self

      def set_primary_geo_node
        node = GeoNode.new(primary: true, name: GeoNode.current_node_name, url: GeoNode.current_node_url)
        $stdout.puts "Saving primary Geo node with name #{node.name} and URL #{node.url} ..."
        node.save

        if node.persisted?
          $stdout.puts "#{node.url} is now the primary Geo node".color(:green)
        else
          $stdout.puts "Error saving Geo node:\n#{node.errors.full_messages.join("\n")}".color(:red)
        end
      end

      def set_secondary_as_primary
        GeoNode.transaction do
          primary_node = GeoNode.primary_node
          current_node = GeoNode.current_node

          abort 'The primary Geo site is not set' unless primary_node
          abort 'Current node is not identified' unless current_node

          if current_node.primary?
            $stdout.puts "#{current_node.url} is already the primary Geo site".color(:green)
          else
            primary_node.destroy
            current_node.update!(primary: true, enabled: true)

            $stdout.puts "#{current_node.url} is now the primary Geo site".color(:green)
          end
        end
      end

      def update_primary_geo_node_url
        node = Gitlab::Geo.primary_node

        unless node.present?
          $stdout.puts 'This is not a primary node'.color(:red)
          exit 1
        end

        $stdout.puts "Updating primary Geo node with URL #{node.url} ..."

        if node.update(name: GeoNode.current_node_name, url: GeoNode.current_node_url)
          $stdout.puts "#{node.url} is now the primary Geo node URL".color(:green)
        else
          $stdout.puts "Error saving Geo node:\n#{node.errors.full_messages.join("\n")}".color(:red)
          exit 1
        end
      end
    end
  end
end
