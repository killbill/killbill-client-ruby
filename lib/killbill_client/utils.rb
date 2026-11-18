module KillBillClient
  module Utils
    ACRONYMS = %w(CBA).freeze

    # Upper bound on the number of cached conversions per cache. Attribute names come from the Kill Bill API,
    # so the set of distinct inputs is small in practice: this is only a safety net against unbounded growth.
    MAX_CACHE_SIZE = 10_000

    # Thread-safe memoization for the string conversions below. They run for every JSON key of every
    # Kill Bill response and request, on a small set of distinct inputs, so caching them avoids a lot of
    # regex work and allocations (in particular on JRuby).
    #
    # Reads never take the lock: they read a frozen Hash, and writers replace it with an updated frozen copy.
    # Cached values are frozen, since they are shared between callers.
    class ConversionCache
      def initialize(max_size = MAX_CACHE_SIZE)
        @max_size = max_size
        @entries = {}.freeze
        @lock = Mutex.new
      end

      def fetch(key)
        value = @entries[key]
        return value unless value.nil?

        value = yield(key).freeze
        @lock.synchronize do
          if @entries.size < @max_size && !@entries.key?(key)
            @entries = @entries.merge((key.frozen? ? key : key.dup.freeze) => value).freeze
          end
        end
        value
      end

      def size
        @entries.size
      end
    end

    UNDERSCORE_CACHE = ConversionCache.new
    CAMELIZE_UPPER_CACHE = ConversionCache.new
    CAMELIZE_LOWER_CACHE = ConversionCache.new

    # Note: the returned String is frozen (and shared), dup it before modifying it.
    def camelize(underscored_word, first_letter = :upper)
      cache = first_letter == :lower ? CAMELIZE_LOWER_CACHE : CAMELIZE_UPPER_CACHE
      cache.fetch(underscored_word.to_s) { |word| camelize_uncached(word, first_letter) }
    end

    def demodulize(class_name_in_module)
      class_name_in_module.to_s.sub(/^.*::/, '')
    end

    # Note: the returned String is frozen (and shared), dup it before modifying it.
    def underscore(camel_cased_word)
      UNDERSCORE_CACHE.fetch(camel_cased_word.to_s) { |word| underscore_uncached(word) }
    end

    def acronym?(word)
      ACRONYMS.include?(word.to_s.upcase)
    end

    def camelize_uncached(underscored_word, first_letter = :upper)
      camelized = underscored_word.to_s.split('_').map do |word|
        if acronym?(word)
          word.upcase
        else
          word[0, 1].upcase + word[1..-1]
        end
      end.join
      camelized = camelized[0, 1].downcase + camelized[1..-1] if first_letter == :lower
      camelized
    end

    def underscore_uncached(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      # Same result as /([A-Z]+)([A-Z][a-z])/ => '\1_\2' ("HTTPResponse" => "HTTP_Response"), but without the
      # quantifier that backtracks polynomially on long runs of capitals (36s for 50,000 "A"s on JRuby).
      word.gsub!(/([A-Z])(?=[A-Z][a-z])/, '\1_')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr! '-', '_'
      word.downcase!
      word
    end

    extend self
  end
end
