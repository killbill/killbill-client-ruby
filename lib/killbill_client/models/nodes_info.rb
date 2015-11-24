module KillBillClient
  module Model
    class NodesInfo < NodeInfoAttributes

      KILLBILL_NODES_INFO_PREFIX = "#{KILLBILL_API_PREFIX}/nodesInfo"

      has_many :plugins_info, KillBillClient::Model::PluginInfoAttributes

      class << self

        def nodes_info(options = {})
          get KILLBILL_NODES_INFO_PREFIX,
              {},
              options
        end

        def trigger_node_command(node_command, local_node_only, user = nil, reason = nil, comment = nil, options = {})
          post KILLBILL_NODES_INFO_PREFIX,
               node_command.to_json,
               {:localNodeOnly => local_node_only},
               {
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end

      end

    end
  end
end
