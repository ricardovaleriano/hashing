module Hashing
  # Define the class methods that should be available in a 'hasherized ®' class
  # (a class that include `Hashing`).
  module Hasherizer
    # Configures which instance variables will be used to compose the `Hash`
    # generated by `#to_h`
    #
    # @api
    # @param ivars_and_options [*arguments]
    def hasherize(*ivars_and_options)
      ivars, raw_options = _extract_ivars ivars_and_options
      @_options = Options.new(raw_options).filter caller.first
      @_ivars ||= []
      @_ivars += ivars.map { |ivar|
        Ivar.new ivar, @_options.strategies[:to], @_options.strategies[:from]
      }
    end

    # Configures the strategy to (re)create an instance of the 'hasherized ®'
    # class based on a `Hash` instance. This strategy will be used by the
    # `.from_hash({})` method.
    #
    # This configuration is optional, if it's not called, then the strategy will
    # be just repassing the `Hash` to the initializer.
    #
    # @param strategy [#call]
    # @return void
    def loading(strategy)
      @_strategy = strategy
    end

    # those methods are private but part of the class api (macros).
    # #TODO: there is a way to document the 'macros' for a class in YARD?
    private :hasherize, :loading

    # provides access to the current configuration on what `ivars` should be
    # used to generate a `Hash` representation of instances of the client class.
    #
    # @return [Array] ivars that should be included in the final Hash
    def _ivars
      @_ivars ||= []
    end

    # Receives a `Hash` and uses the strategy configured by `.loading` to
    # (re)create an instance of the 'hasherized ®' class.
    #
    # @param pairs [Hash] in a valid form defined by `.hasherize`
    # @return new object
    def from_hash(pairs)
      metadata = pairs.delete(:__hashing__) || {}
      hash_to_load = pairs.map do |ivar_name, value|
        ivar = _ivar_by_name ivar_name.to_sym
        [ivar.to_sym, ivar.from_hash(value, metadata)]
      end
      _loading_strategy.call Hash[hash_to_load]
    end

    private
    # Provides the default strategy for recreate objects from hashes (which is
    # just call .new passing the `Hash` as is.
    #
    # @return the result of calling the strategy
    def _loading_strategy
      @_strategy || ->(h) { new h }
    end

    # Cleanup the arguments received by `.hasherize` so only the `ivar` names
    # are returned. This is necessarey since the `.hasherize` can receive a
    # `Hash` with strategies `:from_hash` and `:to_hash` as the last argument.
    #
    # @param ivars_and_options [Array] arguments received by `.serialize`
    # @return [Array[:Symbol]] ivar names that should be used in the `Hash` serialization
    def _extract_ivars(ivars_and_options)
      ivars = ivars_and_options.dup
      options = ivars.last.is_a?(Hash) ? ivars.pop : {}
      return ivars, options
    end

    # Search an `ivar` by it's name in the class ivars collection
    #
    # #TODO: Can be enhanced since now the ivars doesn't have a sense of
    # equality (and they should have)
    #
    # @param ivar_name [Symbol] `ivar` name
    # @return [Ivar]
    def _ivar_by_name(ivar_name)
      ivar = _ivars.select { |ivar| ivar.to_sym == ivar_name }.first
      raise UnconfiguredIvar.new ivar_name, name unless ivar
      ivar
    end
  end
end
