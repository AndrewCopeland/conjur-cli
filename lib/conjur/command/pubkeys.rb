#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'conjur/cli'

class Conjur::Command::Pubkeys < Conjur::Command
  desc "Public keys service operations"
  command :pubkeys do |pubkeys|

    pubkeys.desc "List public keys for the given user"
    pubkeys.arg_name "username"
    pubkeys.command :show do |c|
      c.action do |global_options, options, args|
        username = require_arg args, "username"
        puts api.public_keys(username)
      end
    end

    pubkeys.desc "List the names of a user's public keys"
    pubkeys.arg_name "username"
    pubkeys.command :names do |c|
      c.action do |global_options, options, args|
        username = require_arg args, "username"
        api.public_keys(username)
        .split("\n")
        .map{|k| k.split(' ').last}
        .sort.each{|n| puts n}
      end
    end

    pubkeys.desc "Add a public key for a user"
    pubkeys.arg_name "username key"
    pubkeys.command :add do |c|
      c.action do |global_options, options, args|
        username = require_arg args, "username"
        if key = args.shift
          if /^@(.+)$/ =~ key
            key = File.read(File.expand_path($1))
          end
        else
          key = STDIN.read.strip
        end
        api.add_public_key username, key
        puts "Public key '#{key.split(' ').last}' added"
      end
    end

    pubkeys.desc "Removes a public key for a user"
    pubkeys.arg_name "username keyname"
    pubkeys.command :delete do |c|
      c.action do |global_options, options, args|
        username = require_arg args, "username"
        keyname = require_arg args, "keyname"
        api.delete_public_key username, keyname
        puts "Public key '#{keyname}' deleted"
      end
    end
  end
end