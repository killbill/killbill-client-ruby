module KillBillClient
  module Utils
    def camelize(underscored_word, first_letter = :upper)
      camelized = underscored_word.to_s.gsub(/(?:^|_)(.)/) { $1.upcase }
      case first_letter
        when :lower then
          camelized = camelized[0, 1].downcase + camelized[1..-1]
        else
          # camelized = camelized
      end
      camelized
    end

    def demodulize(class_name_in_module)
      class_name_in_module.to_s.sub(/^.*::/, '')
    end

    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr! '-', '_'
      word.downcase!
      word
    end

    extend self
  end
end
