module KillBillClient
  module Utils
    ACRONYMS = %w(CBA).freeze

    # Small thread-safe, size-bounded memoization table.
    #
    # Reads are lock-free: the table is an immutable (frozen) Hash which is swapped atomically on writes
    # (copy-on-write, guarded by a Mutex). The set of keys we see in practice is tiny and finite (the attribute names
    # of the Kill Bill JSON API), so the cost of copying on a miss is negligible, and the size cap is only a safety
    # net: once it is reached, new keys are simply computed on each call instead of being cached.
    #
    # Values must never be nil or false.
    class Cache
      DEFAULT_MAX_SIZE = 4096

      def initialize(max_size = DEFAULT_MAX_SIZE)
        @max_size = max_size
        @mutex = Mutex.new
        @entries = {}.freeze
      end

      def fetch(key)
        value = @entries[key]
        return value unless value.nil?

        value = yield
        store(key, value)
        value
      end

      def size
        @entries.size
      end

      private

      def store(key, value)
        @mutex.synchronize do
          entries = @entries
          return if entries.size >= @max_size || entries.key?(key)

          updated = entries.dup
          updated[key] = value
          @entries = updated.freeze
        end
      end
    end

    UNDERSCORE_CACHE = Cache.new
    UNDERSCORE_SYMBOLS_CACHE = Cache.new
    CAMELIZE_UPPER_CACHE = Cache.new
    CAMELIZE_LOWER_CACHE = Cache.new

    # Anything that is not already in underscored form: uppercase letters (including non-ASCII ones, which
    # String#downcase! would lowercase), dashes and namespace separators.
    NEEDS_UNDERSCORE = /[[:upper:]]|-|::/

    # @return [String] a frozen string
    def camelize(underscored_word, first_letter = :upper)
      cache = first_letter == :lower ? CAMELIZE_LOWER_CACHE : CAMELIZE_UPPER_CACHE
      return compute_camelize(underscored_word, first_letter).freeze unless cacheable?(underscored_word)

      cache.fetch(underscored_word) { compute_camelize(underscored_word, first_letter).freeze }
    end

    def demodulize(class_name_in_module)
      class_name_in_module.to_s.sub(/^.*::/, '')
    end

    # @return [String] a frozen string
    def underscore(camel_cased_word)
      return compute_underscore(camel_cased_word).freeze unless cacheable?(camel_cased_word)

      UNDERSCORE_CACHE.fetch(camel_cased_word) { compute_underscore(camel_cased_word).freeze }
    end

    # Resolves, in one cached lookup, what is needed to map a JSON attribute name onto a resource attribute.
    #
    # @return [Array<Symbol>] a frozen [attribute_name, setter_name] pair, e.g. [:account_cba, :account_cba=] for 'accountCBA'
    def underscore_symbols(camel_cased_word)
      unless cacheable?(camel_cased_word)
        name = underscore(camel_cased_word).to_sym
        return [name, :"#{name}="].freeze
      end

      UNDERSCORE_SYMBOLS_CACHE.fetch(camel_cased_word) do
        name = underscore(camel_cased_word).to_sym
        [name, :"#{name}="].freeze
      end
    end

    def acronym?(word)
      ACRONYMS.include?(word.to_s.upcase)
    end

    extend self

    private

    # Only immutable-by-convention keys are memoized: Strings are copied and frozen by Hash on insertion, and Symbols
    # are immutable. Anything else (nil, Integer, arbitrary objects with a to_s) is simply computed.
    def cacheable?(value)
      value.is_a?(String) || value.is_a?(Symbol)
    end

    def compute_camelize(underscored_word, first_letter)
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

    def compute_underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      # Fast path: already underscored, nothing to rewrite
      return word unless word =~ NEEDS_UNDERSCORE

      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr! '-', '_'
      word.downcase!
      word
    end
  end
end
