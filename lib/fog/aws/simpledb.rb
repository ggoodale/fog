require 'rubygems'
require 'base64'
require 'cgi'
require 'hmac-sha2'

require File.dirname(__FILE__) + '/simpledb/parsers'

module Fog
  module AWS
    class SimpleDB
      
      # Initialize connection to SimpleDB
      #
      # ==== Notes
      # options parameter must include values for :aws_access_key_id and 
      # :aws_secret_access_key in order to create a connection
      #
      # ==== Examples
      # sdb = SimpleDB.new(
      #  :aws_access_key_id => your_aws_access_key_id,
      #  :aws_secret_access_key => your_aws_secret_access_key
      # )
      #
      # ==== Parameters
      # options<~Hash>:: config arguments for connection.  Defaults to {}.
      #
      # ==== Returns
      # SimpleDB object with connection to aws.
      def initialize(options={})
        @aws_access_key_id      = options[:aws_access_key_id]
        @aws_secret_access_key  = options[:aws_secret_access_key]
        @hmac       = HMAC::SHA256.new(@aws_secret_access_key)
        @host       = options[:host]      || 'sdb.amazonaws.com'
        @namespace  = options[:namespace] || 'http://sdb.amazonaws.com/doc/2007-11-07/'
        @nil_string = options[:nil_string]|| 'nil'
        @port       = options[:port]      || 443
        @scheme     = options[:scheme]    || 'https'
      end

      # Create a SimpleDB domain
      #
      # ==== Parameters
      # domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
      # following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
      # 
      # ==== Returns
      # Hash:: The :request_id and :box_usage values for the request.
      def create_domain(domain_name)
        request({
          'Action' => 'CreateDomain',
          'DomainName' => domain_name
        }, Fog::Parsers::AWS::SimpleDB::BasicParser.new(@nil_string))
      end

      # Delete a SimpleDB domain
      #
      # ==== Parameters
      # domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
      # following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
      # 
      # ==== Returns
      # Hash:: The :request_id and :box_usage values for the request.
      def delete_domain(domain_name)
        request({
          'Action' => 'DeleteDomain',
          'DomainName' => domain_name
        }, Fog::Parsers::AWS::SimpleDB::BasicParser.new(@nil_string))
      end

      # List SimpleDB domains
      #
      # ==== Parameters
      # max_number_of_domains<~Integer>:: Maximum number of domains to return
      # between 1 and 100, defaults to 100.
      # next_token<~Integer>:: Offset token to start list, defaults to nil.
      #
      # ==== Returns
      # Hash:: 
      #   :request_id and :box_usage
      #   :domains array of domain names.
      #   :next_token offset to start with if there are are more domains to list
      def list_domains(max_number_of_domains = nil, next_token = nil)
        request({
          'Action' => 'ListDomains',
          'MaxNumberOfDomains' => max_number_of_domains,
          'NextToken' => next_token
        }, Fog::Parsers::AWS::SimpleDB::ListDomainsParser.new(@nil_string))
      end

      # List metadata for SimpleDB domain
      #
      # ==== Parameters
      # domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
      # following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
      #
      # ==== Returns
      # Hash:: 
      #   :timestamp last update time for metadata.
      #   :item_count number of items in domain
      #   :attribute_value_count number of all name/value pairs in domain
      #   :attribute_name_count number of unique attribute names in domain
      #   :item_name_size_bytes total size of item names in domain, in bytes
      #   :attribute_values_size_bytes total size of attributes, in bytes
      #   :attribute_names_size_bytes total size of unique attribute names, in bytes
      def domain_metadata(domain_name)
        request({
          'Action' => 'DomainMetadata',
          'DomainName' => domain_name
        }, Fog::Parsers::AWS::SimpleDB::DomainMetadataParser.new(@nil_string))
      end

      # Put items attributes into a SimpleDB domain
      #
      # ==== Parameters
      # domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
      #   following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
      #   items<~Hash>:: Keys are the items names and may use any UTF-8
      #   characters valid in xml.  Control characters and sequences not allowed
      #   in xml are not valid.  Can be up to 1024 bytes long.  Values are the
      #   attributes to add to the given item and may use any UTF-8 characters
      #   valid in xml. Control characters and sequences not allowed in xml are
      #   not valid.  Each name and value can be up to 1024 bytes long.
      #
      # ==== Returns
      # Hash:: 
      #   :request_id and :box_usage
      def batch_put_attributes(domain_name, items, replace_attributes = Hash.new([]))
        request({
          'Action' => 'BatchPutAttributes',
          'DomainName' => domain_name
        }.merge!(encode_batch_attributes(items, replace_attributes)), Fog::Parsers::AWS::SimpleDB::BasicParser.new(@nil_string))
      end

      # Put item attributes into a SimpleDB domain
      #
      # ==== Parameters
      # domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
      # following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
      # item_name<~String>:: Name of the item.  May use any UTF-8 characters valid
      #   in xml.  Control characters and sequences not allowed in xml are not
      #   valid.  Can be up to 1024 bytes long.
      # attributes<~Hash>:: Name/value pairs to add to the item.  Attribute names
      #   and values may use any UTF-8 characters valid in xml. Control characters
      #   and sequences not allowed in xml are not valid.  Each name and value can
      #   be up to 1024 bytes long.
      #
      # ==== Returns
      # Hash:: 
      #   :request_id and :box_usage
      def put_attributes(domain_name, item_name, attributes, replace_attributes = [])
        batch_put_attributes(domain_name, { item_name => attributes }, { item_name => replace_attributes })
      end

      # List metadata for SimpleDB domain
      #
      # ==== Parameters
      # domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
      #   following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
      # item_name<~String>:: Name of the item.  May use any UTF-8 characters valid
      #   in xml.  Control characters and sequences not allowed in xml are not
      #   valid.  Can be up to 1024 bytes long.
      # attributes<~Hash>:: Name/value pairs to remove from the item.  Defaults to
      #   nil, which will delete the entire item. Attribute names and values may
      #   use any UTF-8 characters valid in xml. Control characters and sequences
      #   not allowed in xml are not valid.  Each name and value can be up to 1024
      #   bytes long.
      #
      # ==== Returns
      # Hash:: :request_id and :box_usage for request
      def delete_attributes(domain_name, item_name, attributes = nil)
        request({
          'Action' => 'DeleteAttributes',
          'DomainName' => domain_name,
          'ItemName' => item_name
        }.merge!(encode_attributes(attributes)), Fog::Parsers::AWS::SimpleDB::BasicParser.new(@nil_string))
      end

      # List metadata for SimpleDB domain
      #
      # ==== Parameters
      # domain_name<~String>:: Name of domain. Must be between 3 and 255 of the
      #   following characters: a-z, A-Z, 0-9, '_', '-' and '.'.
      # item_name<~String>:: Name of the item.  May use any UTF-8 characters valid
      #   in xml.  Control characters and sequences not allowed in xml are not
      #   valid.  Can be up to 1024 bytes long.
      # attributes<~Hash>:: Name/value pairs to return from the item.  Defaults to
      #   nil, which will return all attributes. Attribute names and values may use
      #   any UTF-8 characters valid in xml. Control characters and sequences not 
      #   allowed in xml are not valid.  Each name and value can be up to 1024
      #   bytes long.
      #
      # ==== Returns
      # Hash:: 
      #   :request_id and :box_usage for request
      #   :attributes list of attribute name/values for the item
      def get_attributes(domain_name, item_name, attributes = nil)
        request({
          'Action' => 'GetAttributes',
          'DomainName' => domain_name,
          'ItemName' => item_name,
        }.merge!(encode_attribute_names(attributes)), Fog::Parsers::AWS::SimpleDB::GetAttributesParser.new(@nil_string))
      end

      # Select item data from SimpleDB
      #
      # ==== Parameters
      # select_expression<~String>:: Expression to query domain with.
      # next_token<~Integer>:: Offset token to start list, defaults to nil.
      #
      # ==== Returns
      # Hash:: 
      #   :request_id and :box_usage for request
      #   :items list of attribute name/values for the items formatted as 
      #     { 'item_name' => { 'attribute_name' => ['attribute_value'] }}
      #   :next_token offset to start with if there are are more domains to list
      def select(select_expression, next_token = nil)
        request({
          'Action' => 'Select',
          'NextToken' => next_token,
          'SelectExpression' => select_expression
        }, Fog::Parsers::AWS::SimpleDB::SelectParser.new(@nil_string))
      end

      private

      def encode_batch_attributes(items, replace_attributes = Hash.new([]))
        encoded_attributes = {}
        item_index = 0
        items.keys.each do |item_key|
          encoded_attributes["Item.#{item_index}.ItemName"] = item_key.to_s
          items[item_key].keys.each do |attribute_key|
            attribute_index = 0
            Array(items[item_key][attribute_key]).each do |value|
              encoded_attributes["Item.#{item_index}.Attribute.#{attribute_index}.Name"] = attribute_key.to_s
              encoded_attributes["Item.#{item_index}.Attribute.#{attribute_index}.Replace"] = 'true' if replace_attributes[item_key].include?(attribute_key)
              encoded_attributes["Item.#{item_index}.Attribute.#{attribute_index}.Value"] = sdb_encode(value)
              attribute_index += 1
            end
            item_index += 1
          end
        end if items
        encoded_attributes
      end

      def encode_attributes(attributes, replace_attributes = [])
        encoded_attributes = {}
        i = 0
        attributes.keys.each do |key|
          Array(attributes[key]).each do |value|
            encoded_attributes["Attribute.#{i}.Name"] = key.to_s
            encoded_attributes["Attribute.#{i}.Replace"] = 'true' if replace_attributes.include?(key)
            encoded_attributes["Attribute.#{i}.Value"] = sdb_encode(value)
            i += 1
          end
        end if attributes
        encoded_attributes
      end

      def encode_attribute_names(attributes)
        encoded_attribute_names = {}
        attributes.each_with_index do |attribute, i|
          encoded_attribute_names["AttributeName.#{i}"] = attribute.to_s
        end if attributes
        encoded_attribute_names
      end

      def sdb_encode(value)
        value.nil? ? @nil_string : value.to_s
      end

      def request(params, parser)
        params.delete_if {|key,value| value.nil? }
        params.merge!({
          'AWSAccessKeyId' => @aws_access_key_id,
          'SignatureMethod' => 'HmacSHA256',
          'SignatureVersion' => '2',
          'Timestamp' => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          'Version' => '2007-11-07'
        })

        query = ''
        params.keys.sort.each do |key|
          query << "#{key}=#{CGI.escape(params[key]).gsub(/\+/, '%20')}&"
        end

        # FIXME: use 'POST' for larger requests
        # method = query.length > 2000 ? 'POST' : 'GET'
        method = 'GET'
        string_to_sign = "#{method}\n#{@host + (@port == 80 ? "" : ":#{@port}")}\n/\n" << query.chop
        hmac = @hmac.update(string_to_sign)
        query << "Signature=#{CGI.escape(Base64.encode64(hmac.digest).strip).gsub(/\+/, '%20')}"
        
        response = nil
        EventMachine::run {
          http = EventMachine.connect(@host, @port, Fog::AWS::Connection) {|connection|
            connection.method = method
            connection.parser = parser
            connection.url = "#{@scheme}://#{@host}:#{@port}/#{method == 'GET' ? "?#{query}" : ""}"
          }
          http.callback {|http| response = http.response}
        }
        response
      end

    end
  end
end