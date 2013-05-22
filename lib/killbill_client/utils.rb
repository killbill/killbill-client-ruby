module KillBillClient
  module Utils
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
