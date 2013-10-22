module KillBillClient
  module Model
    class Resources < ::Array

     attr_reader :etag,
                 :session_id,
                  :pagination_nb_results,
                  :pagination_total_nb_results,
                 :response

    end
  end
end
