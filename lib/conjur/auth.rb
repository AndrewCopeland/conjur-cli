require 'highline'
require 'conjur/api'
require 'netrc'

module Conjur::Auth
  class << self
    def login(options = {})
      delete_credentials
      get_credentials(options)
    end
    
    def delete_credentials
      netrc.delete host
      netrc.save
    end
    
    def host
      ENV['CONJUR_HOST'] || default_host
    end
    
    def default_host
      "localhost:5000"
    end
    
    def netrc
      @netrc ||= Netrc.read
    end
    
    def get_credentials(options = {})
      @credentials ||= (read_credentials || fetch_credentials(options))
    end
    
    def read_credentials
      netrc[host]
    end
    
    def fetch_credentials(options = {})
      ask_for_credentials(options)
      write_credentials
    end
    
    def write_credentials
      netrc[host] = @credentials
      netrc.save
      @credentials
    end
    
    def ask_for_credentials(options = {})
      hl = HighLine.new
      user = options[:username] || hl.ask("Enter your login to log into Conjur: ")
      pass = options[:password] || hl.ask("Please enter your password (it will not be echoed): "){ |q| q.echo = false }
      @credentials = [user, get_api_key(user, pass)]
    end
    
    def get_api_key user, pass
      Conjur::API.get_key(user, pass)
    end
    
    def api(cls = Conjur::API, options = {})
      @api ||= cls.new(*get_credentials(options))
    end
  end
end
