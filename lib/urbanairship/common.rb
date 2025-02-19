require 'urbanairship/loggable'

module Urbanairship
  # Features mixed in to all classes
  module Common
    SERVER = 'go.urbanairship.com'
    BASE_URL = 'https://go.urbanairship.com/api'
    CHANNEL_URL = BASE_URL + '/channels/'
    DEVICE_TOKEN_URL = BASE_URL + '/device_tokens/'
    APID_URL = BASE_URL + '/apids/'
    DEVICE_PIN_URL = BASE_URL + '/device_pins/'
    PUSH_URL = BASE_URL + '/push/'
    DT_FEEDBACK_URL = BASE_URL + '/device_tokens/feedback/'
    APID_FEEDBACK_URL = BASE_URL + '/apids/feedback/'
    SCHEDULES_URL = BASE_URL + '/schedules/'
    TAGS_URL = BASE_URL + '/tags/'
    SEGMENTS_URL = BASE_URL + '/segments/'

    # Helper method for required keyword args in Ruby 2.0 that is compatible with 2.1+
    # @example
    #   def say(greeting: required('greeting'))
    #     puts greeting
    #   end
    #
    #   >> say
    #   >> test.rb:3:in `required': required parameter :greeting not passed to method say (ArgumentError)
    #   >>       from test.rb:6:in `say'
    #   >>       from test.rb:18:in `<main>'
    # @param [Object] arg optional argument name
    def required(arg=nil)
      method = caller_locations(1,1)[0].label
      raise ArgumentError.new("required parameter #{arg.to_sym.inspect + ' ' if arg}not passed to method #{method}")
    end

    # Helper method that sends the indicated method to the indicated object, if the object responds to the method
    # @example
    #   try_helper(:first, [1,2,3])
    #
    #   >> 1
    def try_helper(method, obj)
      if obj.respond_to?(method)
        obj.send(method)
      end
    end

    # Helper method that deletes every key-value pair from a hash for which the value is nil
    # @example
    #   compact_helper({"a" => 1, "b" => nil})
    #
    #   >> {"a" => 1}
    def compact_helper(a_hash)
      a_hash.keep_if {|_, value| !value.nil?}
    end

    class Unauthorized < StandardError
      # raised when we get a 401 from server
    end

    class Forbidden < StandardError
      # raised when we get a 403 from server
    end

    class AirshipFailure < StandardError
      include Urbanairship::Loggable
      # Raised when we get an error response from the server.
      attr_accessor :error, :error_code, :details, :response

      def initialize
        @error = nil
        @error_code = nil
        @details = nil
        @response = nil
      end

      # Instantiate a ValidationFailure from a Response object
      def from_response(response)

        payload = response.body
        @error = payload['error']
        @error_code = payload['error_code']
        @details = payload['details']
        @response = response

        logger.error("Request failed with status #{response.code.to_s}: '#{@error_code} #{@error}': #{response.body}")

        self
      end

    end

    class Response
      # Parse Response Codes and trigger appropriate actions.
      def self.check_code(response_code, response)
        if response_code == 401
          raise Unauthorized, "Client is not authorized to make this request. The authorization credentials are incorrect or missing."
        elsif response_code == 403
          raise Forbidden, "Client is not forbidden from making this request. The application does not have the proper entitlement to access this feature."
        elsif !((200...300).include?(response_code))
          raise AirshipFailure.new.from_response(response)
        end
      end
    end

  end
end
