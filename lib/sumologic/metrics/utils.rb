require 'securerandom'

module Sumologic; class Metrics
  module Utils
    module_function

    # public: Return a new hash with keys converted from strings to symbols
    #
    def symbolize_keys(hash)
      hash.each_with_object({}) do |(k, v), memo|
        memo[k.to_sym] = v
      end
    end

    # public: Convert hash keys from strings to symbols in place
    #
    def symbolize_keys!(hash)
      hash.replace(symbolize_keys(hash))
    end

    # public: Return a new hash with keys as strings
    #
    def stringify_keys(hash)
      hash.each_with_object({}) do |(k, v), memo|
        memo[k.to_s] = v
      end
    end
  end
end; end
