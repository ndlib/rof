# frozen_string_literal: true

require 'strscan'

module ROF
  # Flat is our internal unit for representing a CurateND record.
  # It is conceptually, a PID along with a sequence of key-value pairs
  # where keys and values are strings, and keys may be repeated.
  class Flat
    class NotString < RuntimeError
    end

    class NotSexp < RuntimeError
    end

    attr_accessor :fields # do not access directly

    def initialize
      @fields = {}
    end

    def ==(other)
      return false unless self.class == other.class

      @fields == other.fields
    end

    def find_first(field_name)
      @fields.fetch(field_name, []).first
    end

    def find_all(field_name)
      @fields.fetch(field_name, [])
    end

    def each_field(&block)
      @fields.each(&block)
    end

    # block is given each field name and an array of field values.
    # It returns the new field name and array of new field values.
    # retuen a nil field value to remove the field altogether.
    def update!
      n = {}
      @fields.each do |k, v|
        x = yield(k, v)
        k_n = x.length > 1 ? x[0] : k
        v_n = x.length > 1 ? x[1] : x
        n[k_n] = v_n unless v_n.nil?
        raise NotString if v_n&.detect { |x| !x.is_a?(String) }
      end
      @fields = n
    end

    # add creats a new (field_name, value) entry.
    # nil or empty values will not be added.
    # if value is an array, many such pairs are created.
    # For special behavior, consider add_uniq()
    def add(field_name, value)
      value = value.reject { |x| x.nil? || x.empty? } if value.is_a?(Array)
      return if value.nil? || value.empty?

      v = @fields.fetch(field_name, [])
      @fields[field_name] = if value.is_a?(Array)
                              v + value
                            else
                              v << value
                            end
      raise NotString if @fields[field_name].detect { |x| !x.is_a?(String) }
    end

    def add_uniq(field_name, value)
      add(field_name, value)
      @fields[field_name]&.uniq!
    end

    def add_if_missing(field_name, value)
      add(field_name, value) if @fields[field_name].nil?
    end

    def delete_all(field_name)
      @fields.delete(field_name)
    end

    def set(field_name, value)
      delete_all(field_name)
      add(field_name, value)
    end

    def to_sexp
      out = ["(record\n"]
      @fields.keys.sort.each do |k|
        @fields[k].each do |vv|
          out << if vv.index(/\s|[()]/)
                   "  (#{k} \"#{vv}\")\n"
                 else
                   "  (#{k} #{vv})\n"
                 end
        end
      end
      out << ')'
      out.join('')
    end

    def pretty_print(pp)
      pp.text to_sexp
    end

    def self.from_hash(h)
      result = Flat.new
      h.each do |k, v|
        next unless k.is_a?(String)

        v = Array.wrap(v)
        result.add(k, v)
      end
      result
    end

    def self.from_sexp(s)
      read_sexp(s).first
    end

    # read_sexp() parses one record out of s and returns
    # the pair [new Flat, rest of s]
    def self.read_sexp(str)
      # as we all learned, regexp cannot match balanced parens
      # so we're going to need to do it by hand
      s = StringScanner.new(str)
      result = Flat.new
      token = next_token(s)
      return result, str unless token == '('

      token = next_token(s)
      return result, str unless token == 'record'

      loop do
        token = next_token(s)
        if token == '('
          val = read_paren(s)
          result.add(val[0], val[1..-1]) if val.length > 1
        elsif token == ')'
          return result, s.rest
        else
          # error
          return result, s
        end
      end
    end

    def self.read_paren(s)
      result = []
      loop do
        token = next_token(s)
        if token == '('
          val = read_paren(s)
          result << val
        elsif token.nil? || token == ')'
          return result
        else
          result << token
        end
      end
    end

    def self.next_token(s)
      # s is a StringScanner object
      s.skip(/\s+/)
      tok = s.scan(/[()]|[^[:space:]()"]+|("([^"]|\\")*")/)
      if tok && tok[0] == '"'
        tok = tok[1...-1].gsub(/[\\](.)/, '"' => '"', 'n' => '\n')
      end
      tok
    end
  end
end
