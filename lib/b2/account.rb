require 'json'

module B2
  class Account
    def initialize(account_id, application_key)
      @account_id = account_id
      @application_key = application_key
    end

    def prepare_request
      uri = URI('https://api.backblaze.com/b2api/v1/b2_authorize_account')
      req = Net::HTTP::Get.new(uri)
      req.basic_auth(@account_id, @application_key)

      req
    end

    def authenticate(req)
      http = Net::HTTP.new(req.uri.host, req.uri.port)
      http.use_ssl = true

      res = http.start{|http| http.request(req)}

      case res
      when Net::HTTPSuccess
        json = res.body
      when Net::HTTPRedirection
        fetch(res['location'], limit - 1)
      else
        res.error!
      end
    end

    def parse_response(res)
      json = JSON.parse(res, symbolize_names: true)
      
      @authorization_token = json[:authorizationToken]
      @api_url = json[:apiUrl]
      @download_url = json[:downloadUrl]
    end

    def self.authorize(account_id, application_key)
      account = self.new(account_id, application_key)
      req = account.prepare_request
      res = account.authenticate(req)
      account.parse_response(res)

      account
    end
  end
end
